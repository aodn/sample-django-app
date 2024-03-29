"""
Django settings for app project.

Generated by 'django-admin startproject' using Django 2.1.3.

For more information on this file, see
https://docs.djangoproject.com/en/2.1/topics/settings/

For the full list of settings and their values, see
https://docs.djangoproject.com/en/2.1/ref/settings/
"""

import os
from .aws_secrets import get_secret
import json

# Build paths inside the project like this: os.path.join(BASE_DIR, ...)
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Quick-start development settings - unsuitable for production
# See https://docs.djangoproject.com/en/2.1/howto/deployment/checklist/

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY', 'change_me')

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = bool(int(os.environ.get('DEBUG', 0)))

ALLOWED_HOSTS = []
ALLOWED_HOSTS.extend(
    filter(
        None,
        os.environ.get('ALLOWED_HOSTS', '').split(',')
    )
)

ALLOWED_CIDR_NETS = []
ALLOWED_CIDR_NETS.extend(
    filter(
        None,
        os.environ.get('ALLOWED_CIDR_NETS', '').split(',')
    )
)

DEFAULT_AUTO_FIELD = 'django.db.models.AutoField'

# Application definition
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'rest_framework.authtoken',
    'core',
    'user',
    'recipe',
    'storages'
]

MIDDLEWARE = [
    'allow_cidr.middleware.AllowCIDRMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'app.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'app.wsgi.application'


# Retrieve the database secret
db_secret = None
if bool(int(os.environ.get('GET_DB_SECRET', 1))):
    db_secret = json.loads(get_secret(os.environ.get('DB_SECRET_NAME'), os.environ.get('DB_SECRET_REGION')))

db_pass = os.environ.get('DB_PASS') if db_secret is None else db_secret['password']

# Database
# https://docs.djangoproject.com/en/2.1/ref/settings/#databases

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'HOST': os.environ.get('DB_HOST'),
        'NAME': os.environ.get('DB_NAME'),
        'USER': os.environ.get('DB_USER'),
        'PASSWORD': db_pass,
    }
}


# Password validation
# https://docs.djangoproject.com/en/2.1/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]


# Internationalization
# https://docs.djangoproject.com/en/2.1/topics/i18n/

LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'UTC'

USE_I18N = True

USE_TZ = True


# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/2.1/howto/static-files/

STATIC_URL = '/static/static/'
MEDIA_URL = '/static/media/'

MEDIA_ROOT = '/vol/web/media'
STATIC_ROOT = '/vol/web/static'

AUTH_USER_MODEL = 'core.User'

S3_STORAGE_BACKEND = bool(int(os.environ.get('S3_STORAGE_BACKEND', 1)))
if S3_STORAGE_BACKEND:
    DEFAULT_FILE_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'

AWS_DEFAULT_ACL = 'public-read'
AWS_STORAGE_BUCKET_NAME = os.environ.get('S3_STORAGE_BUCKET_NAME')
AWS_S3_REGION_NAME = os.environ.get('S3_STORAGE_BUCKET_REGION', 'us-east-1')
AWS_QUERYSTRING_AUTH = False

MINIO_STORAGE_BACKEND = bool(int(os.environ.get('MINIO_STORAGE_BACKEND', 1)))
if MINIO_STORAGE_BACKEND and S3_STORAGE_BACKEND:
    AWS_ACCESS_KEY_ID = os.getenv('MINIO_ACCESS_KEY_ID')
    AWS_SECRET_ACCESS_KEY = os.getenv('MINIO_SECRET_ACCESS_KEY')
    AWS_STORAGE_BUCKET_NAME = os.getenv('S3_STORAGE_BUCKET_NAME')
    AWS_S3_ENDPOINT_URL = os.getenv('MINIO_API')
    AWS_S3_USE_SSL = False
