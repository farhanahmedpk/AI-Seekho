# Use an official lightweight Python image
FROM python:3.12-slim

# Set working directory inside the container
WORKDIR /code

# Prevent Python from writing pyc files to disc and buffering stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Copy requirements file first to leverage Docker build caching
COPY ./requirements.txt /code/requirements.txt

# Install dependencies
RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

# Copy the rest of your application code
COPY ./app /code/app

# Expose the port Cloud Run expects (defaults to 8080)
EXPOSE 8080

# Run Uvicorn pointing to your FastAPI instance
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]