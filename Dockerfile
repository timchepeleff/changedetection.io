# pip dependencies install stage
FROM python:3.8-slim as builder

# rustc compiler would be needed on ARM type devices but theres an issue with some deps not building..
ARG CRYPTOGRAPHY_DONT_BUILD_RUST=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl-dev \
    libffi-dev \
    gcc \
    libc-dev \
    libxslt-dev \
    zlib1g-dev \
    g++

RUN mkdir /install
WORKDIR /install

COPY requirements.txt /requirements.txt

RUN pip install --target=/dependencies -r /requirements.txt

# Final image stage
FROM python:3.8-slim

# Actual packages needed at runtime, usually due to the notification (apprise) backend
# rustc compiler would be needed on ARM type devices but theres an issue with some deps not building..
ARG CRYPTOGRAPHY_DONT_BUILD_RUST=1

# Re #93, #73, excluding rustc (adds another 430Mb~)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl-dev \
    libffi-dev \
    gcc \
    libc-dev \
    libxslt-dev \
    zlib1g-dev \
    g++

# https://stackoverflow.com/questions/58701233/docker-logs-erroneously-appears-empty-until-container-stops
ENV PYTHONUNBUFFERED=1

RUN [ ! -d "/datastore" ] && mkdir /datastore

# Copy modules over to the final image and add their dir to PYTHONPATH
COPY --from=builder /dependencies /usr/local
ENV PYTHONPATH=/usr/local

EXPOSE 8080
EXPOSE 5000

# The actual flask app
COPY backend /app/backend
# The eventlet server wrapper
COPY changedetection.py /app/changedetection.py

WORKDIR /app

CMD [ "python", "./changedetection.py" , "-d", "/datastore"]
