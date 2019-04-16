FROM swift:5.0

WORKDIR /code

COPY Package.swift /code/.
RUN swift package resolve
COPY ./Sources /code/Sources
COPY ./Tests /code/Tests

RUN swift build