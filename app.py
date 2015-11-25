from flask import Flask, session, render_template, redirect, url_for, escape, request

def run_app(config_filename=None):
	app = Flask(__name__)
	load_config(app, config_filename)
	# create_db
	return app

def load_config(app, config):
	# Load a default configuration file
	app.config.from_pyfile('config/default.settings')

	# If cfg is empty try to load config file from environment variable
	if config is None and 'DEV' in os.environ:
		config = os.environ['DEV']

	if config is not None:
		app.config.from_pyfile(config)

	if app.config["SECRET_KEY"] is not None:
		app.secret_key = app.config["SECRET_KEY"]

# def create_db():
	# from test.model import db
	# db.init_app(app)

	# from myportail.views.admin import admin
	# from myportail.views.frontend import frontend
	# app.register_blueprint(admin)
	# app.register_blueprint(frontend)

def forgot_password(email=None):
	error = "Email was send"

app = run_app(config_filename="config/web.settings")

@app.route('/')
def index():
	return redirect(url_for('home'))

@app.route('/home')
def home():
	if 'logged_in' in session:
		return render_template("index.html")
	else:
		return redirect(url_for('login'))

@app.route('/login', methods=['GET','POST'])
def login():
	error = None
	if request.method == 'POST':
		if request.form['username'] != 'admin' or request.form['password'] != 'admin' and request.form['email'] == '':
			error = 'Invalid credentials. Please try again.'
		elif request.form['username'] == '' and request.form['password'] == '' and request.form['email'] != '':
			forgot_password(request.form['email'])
		else:
			session['logged_in'] = True
			# flash('You were logged in')
			return redirect(url_for('home'))
	return render_template('login.html',error=error)

@app.route('/logout')
def logout():
	session.pop('logged_in', None)
	return redirect(url_for('home'))


if __name__ == '__main__':
	if app.debug:
		use_debugger = True
		app.logger.debug('Debug Mode Activate')
	try:
		# Disable Flask's debugger if external debugger is requested
		use_debugger = not(app.config.get('DEBUG_WITH_APTANA'))
	except:
		pass
	app.run(use_debugger=use_debugger, debug=app.debug, use_reloader=use_debugger, host=app.config["LISTEN"], port=app.config["PORT"])