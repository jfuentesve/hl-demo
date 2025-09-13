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

# BEGIN_SLOWER_FOR_TRIAGE
# Slower, verbose
ENV DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 \
    DOTNET_NOLOGO=1 \
    NUGET_XMLDOC_MODE=skip \
    # Opcional: sube timeouts
    NUGET_HTTP_TIMEOUT_SECONDS=600 \
    NUGET_PLUGIN_HANDSHAKE_TIMEOUT_IN_SECONDS=30

    COPY HLApi.csproj ./

# 🔎 Paso de diagnóstico de red (opcional pero útil)
RUN curl -I -sS https://api.nuget.org/v3/index.json
# 🔧 Limpia cachés por si quedó algo corrupto
RUN dotnet nuget locals all --clear




# 🔊 RESTORE con detalle: diag + sin paralelo + origen explícito + cache de NuGet montada
RUN --mount=type=cache,id=nuget,target=/root/.nuget/packages \
    bash -lc 'set -euo pipefail; \
      echo "== dotnet --info =="; dotnet --info; date; \
      echo "== check nuget feed =="; curl -I -sS https://api.nuget.org/v3/index.json || true; \
      echo "== nuget sources =="; dotnet nuget list source || true; \
      echo "== RESTORE =="; \
      stdbuf -oL -eL dotnet restore HLApi.csproj \
        -v diag --disable-parallel \
        --source "https://api.nuget.org/v3/index.json" \
        | sed "s/^/[restore] /"; \
      echo "== DONE =="; date'

# ARG NUGET_RESTORE_ARGS=""
# RUN --mount=type=cache,id=nuget,target=/root/.nuget/packages \
#     dotnet restore HLApi.csproj  --source "https://api.nuget.org/v3/index.json" $NUGET_RESTORE_ARGS

## END_SLOWER_FOR_TRIAGE


# # 1) Restore first (better layer cache)
# COPY HLApi.csproj ./
# RUN --mount=type=cache,id=nuget,target=/root/.nuget/packages \
#     dotnet restore HLApi.csproj -v n



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
