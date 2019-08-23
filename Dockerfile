FROM golang:1.12

RUN go get github.com/golang/protobuf/protoc-gen-go && \
	go get github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway && \
	go get github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger && \
	go get github.com/lnnujxxy/protoc-gen-validate && \
	go get github.com/youlu-cn/grpc-gen/protoc-gen-auth && \
	go get github.com/youlu-cn/grpc-gen/protoc-gen-markdown

FROM gcc:6

# Compile protoc-gen-objcgrpc
RUN git clone https://github.com/grpc/grpc && cd grpc && git checkout $(curl -L https://grpc.io/release) && \
	git submodule update --init && make grpc_objective_c_plugin

FROM java:8

# Source
RUN echo "deb http://mirrors.163.com/debian/ jessie main non-free contrib" > /etc/apt/sources.list && \
	echo "deb http://mirrors.163.com/debian/ jessie-updates main non-free contrib" >> /etc/apt/sources.list && \
    echo "deb http://mirrors.163.com/debian-security/ jessie/updates main non-free contrib" >> /etc/apt/sources.list && \
	rm -rf /etc/apt/sources.list.d/*

# protoc
# TODO version
RUN curl -OL https://github.com/protocolbuffers/protobuf/releases/download/v3.9.1/protoc-3.9.1-linux-x86_64.zip && \
	unzip protoc-3.9.1-linux-x86_64.zip -d protoc3 && mv protoc3/bin/* /usr/local/bin/ && mv protoc3/include/* /usr/local/include/ && \
	rm -rf protoc-3.9.1-linux-x86_64.zip protoc3

# Dart
RUN apt update && apt install -y apt-transport-https make && \
	sh -c 'curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -' && \
	sh -c 'curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list' && \
	apt update && apt install -y dart && \
	/usr/lib/dart/bin/pub global activate protoc_plugin && ln -s /root/.pub-cache/bin/protoc-gen-dart /usr/local/bin/

# protoc-gen-grpc-java
# TODO version
RUN curl -OL https://repo1.maven.org/maven2/io/grpc/protoc-gen-grpc-java/1.23.0/protoc-gen-grpc-java-1.23.0-linux-x86_64.exe && \
	mv protoc-gen-grpc-java-1.23.0-linux-x86_64.exe /usr/local/bin/protoc-gen-grpc-java && chmod +x /usr/local/bin/protoc-gen-grpc-java

# protoc-gen-objcgrpc
COPY --from=1 /grpc/bins/opt/grpc_objective_c_plugin /usr/local/bin/protoc-gen-objcgrpc

# go binaries
COPY --from=0 /go/bin/* /usr/local/bin/

# GOPATH, proto including files required
COPY --from=0 /go/src /data/golang/src
ENV GOPATH /data/golang

