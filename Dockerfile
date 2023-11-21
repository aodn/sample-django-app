FROM python:3.10
LABEL maintainer="stefan@crunchyapple.net.au"

ARG USER_ID=1000

ENV PYTHONUNBUFFERED 1
ENV PIP_ROOT_USER_ACTION=ignore
ENV PATH="/scripts:${PATH}"

COPY ./requirements.txt /requirements.txt
RUN pip install -r /requirements.txt

RUN mkdir /app
WORKDIR /app
COPY ./app /app
COPY ./scripts /scripts
RUN chmod +x /scripts/*

RUN mkdir -p /vol/web/media
RUN mkdir -p /vol/web/static
RUN adduser --uid $USER_ID user
RUN chown -R user:user /vol/
RUN chmod -R 755 /vol/web
USER user

CMD ["entrypoint.sh"]
