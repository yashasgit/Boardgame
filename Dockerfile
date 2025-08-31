FROM python:3.9-slim
WORKDIR /app
COPY . /app
# Replace the requirements.txt line with direct installation
RUN pip install --no-cache-dir Flask==2.3.2
EXPOSE 5000
ENV FLASK_APP=app.py
ENV FLASK_RUN_HOST=0.0.0.0
CMD ["flask", "run"]
