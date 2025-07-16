FROM python:3.11-slim

WORKDIR /app

COPY testing/httpserver/server.py .

RUN pip install flask

EXPOSE 5000

CMD ["flask", "--app", "server", "run", "--host=0.0.0.0", "--port=5000"]