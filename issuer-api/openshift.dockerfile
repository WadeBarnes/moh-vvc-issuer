###################################
### Stage 1 - Build environment ###
###################################
# FROM mcr.microsoft.com/dotnet/core/sdk:3.1 AS build
FROM registry.access.redhat.com/ubi8/dotnet-31 AS build
WORKDIR /opt/app-root/app
ARG API_PORT
ARG ASPNETCORE_ENVIRONMENT
ARG POSTGRESQL_PASSWORD
ARG POSTGRESQL_DATABASE
ARG POSTGRESQL_ADMIN_PASSWORD
ARG POSTGRESQL_USER
ARG SUFFIX
ARG DB_HOST

ENV PATH="$PATH:/opt/rh/rh-dotnet31/root/usr/bin/:/opt/app-root/app/.dotnet/tools:/root/.dotnet/tools:/opt/app-root/.dotnet/tools"

ENV API_PORT 8080
ENV ASPNETCORE_ENVIRONMENT "${ASPNETCORE_ENVIRONMENT}"
ENV POSTGRESQL_PASSWORD "${POSTGRESQL_PASSWORD}"
ENV POSTGRESQL_DATABASE "${POSTGRESQL_DATABASE}"
ENV POSTGRESQL_ADMIN_PASSWORD "${POSTGRESQL_ADMIN_PASSWORD}"
ENV POSTGRESQL_USER "${POSTGRESQL_USER}"
ENV SUFFIX "${SUFFIX}"
ENV DB_HOST "$DB_HOST"

# Copy everything and build
COPY . .

RUN dotnet restore "issuer.API.csproj"
RUN dotnet build "issuer.API.csproj" -c Release -o /opt/app-root/app/out
RUN dotnet publish "issuer.API.csproj" -c Release -o /opt/app-root/app/out /p:MicrosoftNETPlatformLibrary=Microsoft.NETCore.App

# Begin database migration setup
RUN dotnet tool install --global dotnet-ef --version 3.1.1
RUN dotnet ef migrations script --idempotent --output /opt/app-root/app/out/databaseMigrations.sql

########################################
### Stage 2 - Production environment ###
########################################
# FROM registry.redhat.io/dotnet/dotnet-31-rhel7 AS runtime
FROM registry.access.redhat.com/ubi8/dotnet-31-runtime AS runtime

ENV API_PORT 8080

WORKDIR /opt/app-root/app
COPY --from=build /opt/app-root/app /opt/app-root/app

RUN yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm &&\
    yum install -yqq http://mirror.centos.org/centos/8-stream/AppStream/x86_64/os/Packages/xorg-x11-fonts-75dpi-7.5-19.el8.noarch.rpm

RUN yum update -yqq && \
    yum install -y postgresql10 gpg gnupg2 wget && \
    yum install -yqq gpg gnupg2 wget

RUN chmod +x entrypoint.sh && \
    chmod 777 entrypoint.sh && \
    chmod -R 777 /var/run/ && \
    chmod -R 777 /opt/app-root && \
    chmod -R 777 /opt/app-root/.*

RUN chmod +x entrypoint.sh
RUN chmod 777 entrypoint.sh
# RUN chmod -R 777 /var/run/
RUN chmod -R 777 /opt/app-root/app
# RUN chmod -R 777 /app/.*

EXPOSE 8080 5001 1025
# ENTRYPOINT [ "./entrypoint.sh" ]
