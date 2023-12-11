# Build arguments
ARG PYTHON_VERSION=3.10-slim

# Start Python image
FROM python:${PYTHON_VERSION}

# Install git
RUN apt-get update && \
    apt-get install -y git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Setting environment with prefect version
ARG PREFECT_VERSION=1.4.1
ENV PREFECT_VERSION $PREFECT_VERSION

# Setup Oracle Instant Client and SQL Server ODBC Driver
WORKDIR /opt/oracle
COPY --from=unzip-step /tmp/instantclient_21_5 /opt/oracle/instantclient_21_5
RUN apt-get update && \
    apt-get install --no-install-recommends -y curl gnupg2 libaio1 && \
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    echo "deb [arch=amd64,arm64,armhf] https://packages.microsoft.com/debian/12/prod bookworm main" > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install --no-install-recommends -y ffmpeg libsm6 libxext6 msodbcsql17 openssl unixodbc-dev && \
    rm -rf /var/lib/apt/lists/* && \
    sh -c "echo /opt/oracle/instantclient_21_5 > /etc/ld.so.conf.d/oracle-instantclient.conf" && \
    ldconfig
COPY ./openssl.cnf /etc/ssl/openssl.cnf

# Setup virtual environment and prefect
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN python3 -m pip install --no-cache-dir -U "pip>=21.2.4" "prefect==$PREFECT_VERSION"

# Install requirements
WORKDIR /app
COPY . .
RUN python3 -m pip install --prefer-binary --no-cache-dir -U .