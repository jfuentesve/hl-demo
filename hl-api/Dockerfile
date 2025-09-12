# syntax=docker/dockerfile:1.6

# --- runtime ---
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080
# (opcional, si no lo inyectas por env en ECS)
# ENV ASPNETCORE_URLS=http://+:8080

# --- build/publish ---
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Acelera el primer uso y reduce ruido
ENV DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 \
    DOTNET_NOLOGO=1 \
    NUGET_XMLDOC_MODE=skip

# 1) Separa el restore para cachearlo
COPY HLApi.csproj ./
RUN --mount=type=cache,id=nuget,target=/root/.nuget/packages \
    dotnet restore HLApi.csproj -v n

# 2) Copia el resto y publica (también usando cache de NuGet)
COPY . .
RUN --mount=type=cache,id=nuget,target=/root/.nuget/packages \
    dotnet publish HLApi.csproj -c Release -o /app/publish /p:UseAppHost=false

# --- final image ---
FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "HLApi.dll"]
