css:
	npx tailwindcss -i input.css -o index.css --minify --watch
	
serve:
	python -m http.server --directory . 8080