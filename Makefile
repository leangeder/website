.PHONY: create update dev delete
.DEFAULT_GOAL := dev

UNAME := $(shell uname -s | tr A-Z a-z)
ifeq ($(OS),Windows_NT)
	UNAME := windows_nt
endif
TIMESTAMP = $(shell date +%s )
REPO_CONTAINER := leangeder
PROJECT_NAME := $(notdir $(CURDIR))
REPO_SOURCE := git@github.com:leangeder/$(PROJECT_NAME)
REPO_DEPLOY := git@github.com:leangeder/kube

/usr/local/bin/minikube: $(PATH_BEAMERY_META)
	@curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-$(UNAME)-amd64
	@chmod +x minikube
	@sudo mv minikube /usr/local/bin/
ifeq ($(UNAME),windows_nt)
	@curl -Lo minikube.exe https://storage.googleapis.com/minikube/releases/latest/minikube-windows-amd64.exe
endif

/usr/local/bin/kubectl:
	@curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/$$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/$(UNAME)/amd64/kubectl
	@chmod +x kubectl
	@sudo mv kubectl /usr/local/bin/
ifeq ($(UNAME),windows_nt)
	@curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/windows/amd64/kubectl.exe
endif

.up: /usr/local/bin/minikube /usr/local/bin/kubectl
ifeq (0,$(shell minikube status | grep Running | wc -l))
	minikube config set WantReportErrorPrompt false
	minikube start --cpus=4 --memory=8192 --mount --mount-string $(CURDIR):/$(PROJECT_NAME)
	# minikube start --memory=6144 --extra-config=apiserver.authorization-mode=RBAC --extra-config=controller-manager.cluster-signing-cert-file="/var/lib/localkube/certs/ca.crt" --extra-config=controller-manager.cluster-signing-key-file="/var/lib/localkube/certs/ca.key" --extra-config=apiserver.admission-control="NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota"
	# -minikube addons disable ingress
	# -minikube addons disable heapster
endif

/tmp/deploy:
	git clone $(REPO_DEPLOY) /tmp/deploy
	
/tmp/deploy/apps/$(PROJECT_NAME): /tmp/deploy
	cd /tmp/deploy; git checkout -b feature/add_$(PROJECT_NAME)
	mkdir -p $@ 

/tmp/deploy/apps/$(PROJECT_NAME)/deploy.yml: /tmp/deploy/apps/$(PROJECT_NAME) .gitignore .dockerignore
	kubectl run $(PROJECT_NAME) --image=$(REPO_CONTAINER)/$(PROJECT_NAME):last --dry-run --image-pull-policy="IfNotPresent" --labels="app=$(PROJECT_NAME)" --namespace= --port=8080 --replicas=1 -o yaml > /tmp/deploy/apps/$(PROJECT_NAME)/deploy.yml
	kubectl expose -f /tmp/deploy/apps/$(PROJECT_NAME)/deploy.yml --name=$(PROJECT_NAME) --labels="app=$(PROJECT_NAME)" --port=8080 --selector="app=$(PROJECT_NAME)" --dry-run -o yaml > /tmp/deploy/apps/$(PROJECT_NAME)/service.yml
	cd /tmp/deploy/; git add apps/$(PROJECT_NAME); git commit -m "Set K8S Manifeste for $(PROJECT_NAME): $(shell date +%c)"
	# cd /tmp/deploy/; git add apps/$(PROJECT_NAME); git commit -m "Set K8S Manifeste for $(PROJECT_NAME): $(shell date +%c)"; git push
	ln -fs /tmp/deploy/apps/$(PROJECT_NAME)/ $(CURDIR)/.deploy
	eval $$(minikube docker-env); docker build -t $(REPO_CONTAINER)/$(PROJECT_NAME):last -f Dockerfile .;

.gitignore:
	echo ".deploy/" > .gitignore

.dockerignore:
	echo ".deploy/" > .dockerignore
	echo "Dockerfile" >> .dockerignore
	echo ".git*" >> .dockerignore
	echo ".dockerignore" >> .dockerignore

delete: .up
	kubectl delete -R -f .deploy --force

full_delete:
	minikube delete

update: .up
	eval $$(minikube docker-env); docker build -t $(REPO_CONTAINER)/$(PROJECT_NAME):$(TIMESTAMP) -f Dockerfile .;
	kubectl set image -f .deploy/deploy.yml $(PROJECT_NAME)=$(REPO_CONTAINER)/$(PROJECT_NAME):$(TIMESTAMP)

create: .up /tmp/deploy/apps/$(PROJECT_NAME)/deploy.yml
	# kubectl apply -f /tmp/deploy/services --overwrite
	kubectl apply -f .deploy/ --overwrite 

/tmp/dev_$(PROJECT_NAME).yml:
	eval $$(minikube docker-env); docker build --target dev -t $(REPO_CONTAINER)/$(PROJECT_NAME):dev -f Dockerfile .
	$(eval DOCKER_SRC_PATH := $(shell grep -E "(COPY|ADD)\ \." Dockerfile | cut -d\  -f 3))
	echo "spec:\n  template:\n    spec:\n      containers:\n      - name: $(PROJECT_NAME)\n        volumeMounts:\n        - name: src\n          mountPath: $(DOCKER_SRC_PATH)\n      volumes:\n      - name: src\n        hostPath:\n          path: /$(PROJECT_NAME)\n          type: Directory" > /tmp/dev_$(PROJECT_NAME).yml

dev: .up create /tmp/dev_$(PROJECT_NAME).yml
	kubectl patch -f .deploy/deploy.yml --patch "$$(cat /tmp/dev_$(PROJECT_NAME).yml)"
	kubectl logs -f .deploy/deploy.yml -f  
