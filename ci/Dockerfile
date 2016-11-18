FROM ubuntu:15.04

RUN set -ex

RUN apt-get update && apt-get install -yq unzip openssh-client curl git
RUN	curl https://storage.googleapis.com/dart-archive/channels/stable/release/1.12.2/sdk/dartsdk-linux-x64-release.zip > dart-sdk.zip
RUN unzip dart-sdk.zip
RUN rm dart-sdk.zip && apt-get clean

env PATH "$HOME/.pub-cache/bin:$HOME/dart-sdk/bin:$PATH"
env DART_SDK "$HOME/dart-sdk"

RUN echo $PATH
RUN pub global activate tuneup
