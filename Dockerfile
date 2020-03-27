FROM golang:1.12

RUN go get github.com/golang/protobuf/protoc-gen-go && \
	go get github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway && \
	go get github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger && \
	go get github.com/lnnujxxy/protoc-gen-validate && \
	go get github.com/youlu-cn/grpc-gen/protoc-gen-auth && \
	go get github.com/youlu-cn/grpc-gen/protoc-gen-markdown && \
	go get github.com/youlu-cn/grpc-gen/protoc-gen-dart-export

FROM gcc:6

# Compile protoc-gen-objcgrpc
RUN git clone https://github.com/grpc/grpc && cd grpc && git checkout $(curl -L https://grpc.io/release) && \
	git submodule update --init && make grpc_objective_c_plugin

FROM mcr.microsoft.com/dotnet/core/sdk:3.1

# grpc_csharp_plugin version: https://www.nuget.org/packages/Grpc.Tools
ENV PLUGIN_VER 2.27.0
RUN cd /root && dotnet new console && \
	dotnet add package Grpc.Tools --version ${PLUGIN_VER} && \
	cp /root/.nuget/packages/grpc.tools/${PLUGIN_VER}/tools/linux_x64/grpc_csharp_plugin /usr/local/bin/grpc_csharp_plugin

FROM debian:jessie

# Protocol Buffers version: https://github.com/protocolbuffers/protobuf/releases/latest
ENV PROTOC_VER 3.11.4
# protoc-gen-grpc-java version: https://mvnrepository.com/artifact/io.grpc/protoc-gen-grpc-java
ENV JAVA_GRPC_VER 1.28.0
# protoc-gen-grpc-web version: https://github.com/grpc/grpc-web/releases/latest
ENV WEB_GRPC_VER 1.0.7

# Jessie has been archived; sources.list should be updated
RUN echo "deb http://archive.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/jessie-backports.list && \
	echo 'Acquire::Check-Valid-Until no;' > /etc/apt/apt.conf.d/99no-check-valid-until

# protoc-gen-dart
RUN apt update && apt install -y apt-transport-https make curl && \
	sh -c 'curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -' && \
	sh -c 'curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list' && \
	apt update && apt install -y dart && \
	/usr/lib/dart/bin/pub global activate protoc_plugin && ln -s /root/.pub-cache/bin/protoc-gen-dart /usr/local/bin/

# protoc
RUN curl -OL https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VER}/protoc-${PROTOC_VER}-linux-x86_64.zip && \
	unzip protoc-${PROTOC_VER}-linux-x86_64.zip -d protoc3 && mv protoc3/bin/* /usr/local/bin/ && mv protoc3/include/* /usr/local/include/ && \
	rm -rf protoc-${PROTOC_VER}-linux-x86_64.zip protoc3

# protoc-gen-grpc-java
RUN curl -OL https://repo1.maven.org/maven2/io/grpc/protoc-gen-grpc-java/${JAVA_GRPC_VER}/protoc-gen-grpc-java-${JAVA_GRPC_VER}-linux-x86_64.exe && \
	mv protoc-gen-grpc-java-${JAVA_GRPC_VER}-linux-x86_64.exe /usr/local/bin/protoc-gen-grpc-java && chmod +x /usr/local/bin/protoc-gen-grpc-java

# protoc-gen-grpc-web
RUN curl -OL https://github.com/grpc/grpc-web/releases/download/${WEB_GRPC_VER}/protoc-gen-grpc-web-${WEB_GRPC_VER}-linux-x86_64 && \
	mv protoc-gen-grpc-web-${WEB_GRPC_VER}-linux-x86_64 /usr/local/bin/protoc-gen-grpc-web && chmod +x /usr/local/bin/protoc-gen-grpc-web

# grpc_csharp_plugin
COPY --from=2 /usr/local/bin/grpc_csharp_plugin /usr/local/bin/grpc_csharp_plugin

# protoc-gen-objcgrpc
COPY --from=1 /usr/local/lib64/libstdc++.so.6.0.22 /usr/lib/x86_64-linux-gnu/libstdc++.so.6.0.20
COPY --from=1 /grpc/bins/opt/grpc_objective_c_plugin /usr/local/bin/protoc-gen-objcgrpc

# go binaries
COPY --from=0 /go/bin/* /usr/local/bin/

# GOPATH, proto including files required
COPY --from=0 /go/src /go/src

ENV GOPATH /go

WORKDIR /mnt
