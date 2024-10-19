FROM python:3.13-slim

# Set the working directory
WORKDIR /code/api

# Copy the current directory contents into the container at /code
COPY ./requirements.txt /code/api/requirements.txt

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir --upgrade -r /code/api/requirements.txt

# Copy the current directory contents into the container at /code
COPY . /code/api

# Run app.py when the container launches
CMD ["fastapi", "run", "--host", "0.0.0.0", "--port", "80"]