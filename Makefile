all:
	npx tailwindcss --minify -i ./css/style.css -o ./static/css/style.css && zola build

init:
	npm install

serve:
	watchexec -r -- "npx tailwindcss --minify -i ./css/style.css -o ./static/css/style.css && zola serve"