.. Deploy to Kuberenetes documentation master file, created by
   sphinx-quickstart on Wed Jul 25 19:01:24 2018.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Deploying a Stack to Kuberenetes
================================

This is a work in progress guide for installing a local kubernetes cluster with helm on a single Ubuntu host (validated on Ubuntu 18.04). Once the cluster is running, you can deploy the following docker containers to run the `AntiNex stack <https://github.com/jay-johnson/train-ai-with-django-swagger-jwt>`__:

- `Redis <https://hub.docker.com/r/bitnami/redis/>`__
- `Postgres <https://github.com/CrunchyData/crunchy-containers>`__
- `Django REST API with JWT and Swagger <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/api/deployment.yml>`__
- `Django REST API Celery Workers <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/worker/deployment.yml>`__
- `Jupyter <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/jupyter/deployment.yml>`__
- `Core Celery Workers <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/core/deployment.yml>`__
- `pgAdmin4 <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/pgadmin/crunchy-template-http.json>`__
- `(Optional) Splunk with TCP and HEC Service Endpoints <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/splunk/deployment.yml>`__

Table of Contents
-----------------

.. toctree::
   :maxdepth: 2

   main

AntiNex Stack Status
--------------------

Here are the AntiNex repositories, documentation and build reports:

.. list-table::
   :header-rows: 1

   * - Component
     - Build
     - Docs Link
     - Docs Build
   * - `REST API <https://github.com/jay-johnson/train-ai-with-django-swagger-jwt>`__
     - .. image:: https://travis-ci.org/jay-johnson/train-ai-with-django-swagger-jwt.svg?branch=master
           :alt: Travis Tests
           :target: https://travis-ci.org/jay-johnson/train-ai-with-django-swagger-jwt.svg
     - `Docs <http://antinex.readthedocs.io/en/latest/>`__
     - .. image:: https://readthedocs.org/projects/antinex/badge/?version=latest
           :alt: Read the Docs REST API Tests
           :target: https://readthedocs.org/projects/antinex/badge/?version=latest
   * - `Core Worker <https://github.com/jay-johnson/antinex-core>`__
     - .. image:: https://travis-ci.org/jay-johnson/antinex-core.svg?branch=master
           :alt: Travis AntiNex Core Tests
           :target: https://travis-ci.org/jay-johnson/antinex-core.svg
     - `Docs <http://antinex-core-worker.readthedocs.io/en/latest/>`__
     - .. image:: https://readthedocs.org/projects/antinex-core-worker/badge/?version=latest
           :alt: Read the Docs AntiNex Core Tests
           :target: http://antinex-core-worker.readthedocs.io/en/latest/?badge=latest
   * - `Network Pipeline <https://github.com/jay-johnson/network-pipeline>`__
     - .. image:: https://travis-ci.org/jay-johnson/network-pipeline.svg?branch=master
           :alt: Travis AntiNex Network Pipeline Tests
           :target: https://travis-ci.org/jay-johnson/network-pipeline.svg
     - `Docs <http://antinex-network-pipeline.readthedocs.io/en/latest/>`__
     - .. image:: https://readthedocs.org/projects/antinex-network-pipeline/badge/?version=latest
           :alt: Read the Docs AntiNex Network Pipeline Tests
           :target: https://readthedocs.org/projects/antinex-network-pipeline/badge/?version=latest
   * - `AI Utils <https://github.com/jay-johnson/antinex-utils>`__
     - .. image:: https://travis-ci.org/jay-johnson/antinex-utils.svg?branch=master
           :alt: Travis AntiNex AI Utils Tests
           :target: https://travis-ci.org/jay-johnson/antinex-utils.svg
     - `Docs <http://antinex-ai-utilities.readthedocs.io/en/latest/>`__
     - .. image:: https://readthedocs.org/projects/antinex-ai-utilities/badge/?version=latest
           :alt: Read the Docs AntiNex AI Utils Tests
           :target: http://antinex-ai-utilities.readthedocs.io/en/latest/?badge=latest
   * - `Client <https://github.com/jay-johnson/antinex-client>`__
     - .. image:: https://travis-ci.org/jay-johnson/antinex-client.svg?branch=master
           :alt: Travis AntiNex Client Tests
           :target: https://travis-ci.org/jay-johnson/antinex-client.svg
     - `Docs <http://antinex-client.readthedocs.io/en/latest/>`__
     - .. image:: https://readthedocs.org/projects/antinex-client/badge/?version=latest
           :alt: Read the Docs AntiNex Client Tests
           :target: https://readthedocs.org/projects/antinex-client/badge/?version=latest

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
