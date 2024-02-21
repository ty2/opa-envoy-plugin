# Copyright 2018 The OPA Authors. All rights reserved.
# Use of this source code is governed by an Apache2
# license that can be found in the LICENSE file.

ARG BASE

### Builder
FROM --platform=$BUILDPLATFORM golang:1.22.0 as builder

ENV OUTDIR=/out/usr/local/bin
RUN mkdir -p ${OUTDIR}

WORKDIR /workspace
COPY go.mod go.sum /workspace/

RUN go mod download

COPY . /workspace/

ARG TARGETOS
ARG TARGETARCH

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build \
    -o /out/opa-envoy-plugin cmd/opa-envoy-plugin/main.go

FROM ${BASE}

# Any non-zero number will do, and unfortunately a named user will not, as k8s
# pod securityContext runAsNonRoot can't resolve the user ID:
# https://github.com/kubernetes/kubernetes/issues/40958. Make root (uid 0) when
# not specified.
ARG USER=0

MAINTAINER Ashutosh Narkar  <anarkar4387@gmail.com>

USER ${USER}

WORKDIR /app

COPY --from=builder /out/ /app/

ENTRYPOINT ["./opa-envoy-plugin"]

CMD ["run"]
