# install docker
FROM ubuntu:16.04
RUN echo 'Installing Docker...'
RUN apt-get update
RUN apt-get -y install virtualbox apt-transport-https ca-certificates curl software-properties-common
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
RUN apt-get update
RUN apt-get -y install docker-ce
RUN echo 'Add user to docker group'
RUN echo $(whoami)
RUN usermod -aG docker $(whoami)
RUN echo 'Starting Docker...'
RUN echo $PWD
RUN which docker
RUN service docker stop
RUN service docker start
RUN docker run --rm -v $PWD:$PWD -w $PWD -v /var/run/docker.sock:/var/run/docker.sock hello-world

# build project
FROM maven:3.5.3-jdk-8 as builder
RUN echo 'Building project...'
COPY agent/ /jenkins/src/agent/
COPY kafka-client-lib/ /jenkins/src/kafka-client-lib/
COPY plugin/ /jenkins/src/plugin/
COPY pom.xml /jenkins/src/pom.xml

WORKDIR /jenkins/src/
RUN mvn clean install --batch-mode

# copy agent
FROM ubuntu
RUN apt-get update && apt-get install -y software-properties-common
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
    add-apt-repository -y ppa:webupd8team/java && \
    apt-get update && \
    apt-get install -y oracle-java8-installer && \
    apt-get install -y iputils-ping && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/oracle-jdk8-installer
COPY --from=builder /jenkins/src/agent/target/remoting-kafka-agent.jar remoting-kafka-agent.jar
ENTRYPOINT ["java", "-jar", "remoting-kafka-agent.jar"]
CMD ["-help"]
