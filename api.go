package api

import (
	// "encoding/json"
	"net/http"
	"log"
	"time"

	"github.com/gorilla/mux"
)

type Book struct {
	db		string	`json`
	// db *gorm.DB
}
// Get All Books
func getBooks(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	// json.NewEncoder(w).Encode(books)
}

// Get a Book
func getBook(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	// params := mux.Vars(r) //Get params
	// for _, item := range books {
	// 	if item.ID == params["id"] {
	// 		json.NewEncoder(w).Encode(item)
	// 		// return
	// 	}
	// }
	// // json.NewEncoder(w).Encode(&Book{})
}

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Do stuff here
		log.Println(r.RequestURI)
		// Call the next handler, which can be another middleware in the chain, or the final handler.
		next.ServeHTTP(w, r)
	})
}

func main() {
	// Init Router
	books := &Book{db: connect()}
   // Create logger
	logger := log.New(os.Stdout, "", 0)
	r := mux.NewRouter()

	r.HandleFunc("/api/books/{id}", books.getBook).Methods("GET")
	r.HandleFunc("/api/books/{id}", books.getBook).Methods("GET")

	r.Use(loggingMiddleware)

	srv := &http.Server{
		Handler:			r,
		Addr:				":8080",
		WriteTimeout:	15 * time.Second,
		ReadTimeout:	15 * time.Second,
	}

	log.Fatal(srv.ListenAndServe())
}
