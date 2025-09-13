# syntax=docker/dockerfile:1.6

# --- runtime ---
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080
# Make Kestrel listen on 0.0.0.0:8080 (ALB health checks hit this)
ENV ASPNETCORE_URLS=http://+:8080

# --- build / publish ---
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Faster, quieter restores
ENV DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 \
    DOTNET_NOLOGO=1 \
    NUGET_XMLDOC_MODE=skip

# 1) Restore first (better layer cache)
COPY HLApi.csproj ./
RUN --mount=type=cache,id=nuget,target=/root/.nuget/packages \
    dotnet restore HLApi.csproj -v n

# 2) Copy the rest and publish
COPY . .
RUN --mount=type=cache,id=nuget,target=/root/.nuget/packages \
    dotnet publish HLApi.csproj -c Release -o /app/publish \
    -p:UseAppHost=false
    # If you prefer RID-specific output, uncomment:
    # -r linux-x64 --no-self-contained

# --- final image ---
FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet","HLApi.dll"]
