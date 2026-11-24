# OpenTodo for Railway: the official release image, pinned by version and digest,
# plus BusyBox for a small start script (the upstream image is distroless).
FROM busybox:1.37.0-musl@sha256:f6a95d611e0a8780fabdb2aec43e31275b2720dfefa3e41b16835bfc42454478 AS busybox

FROM ghcr.io/opentodoapp/opentodo:1.7.0@sha256:c156bc53b3629934760b15505f404954fdbec65b890c1f3b1438d78f851a9840
COPY --from=busybox /bin/busybox /bin/busybox
COPY --chmod=0755 start.sh /start.sh
# Root only for the start script: it gives the Railway volume to the image's
# nonroot user (65532) and then drops to that user before starting OpenTodo.
USER root
ENV OPENTODO_DATA_DIR=/data
EXPOSE 8080
ENTRYPOINT ["/bin/busybox", "sh", "/start.sh"]
