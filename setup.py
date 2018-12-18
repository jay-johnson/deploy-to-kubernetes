import os
import sys
import warnings

try:
    from setuptools import setup
except ImportError:
    from distutils.core import setup

from setuptools.command.test import test as TestCommand


class PyTest(TestCommand):
    user_options = [('pytest-args=', 'a', 'Arguments to pass to pytest')]

    def initialize_options(self):
        TestCommand.initialize_options(self)
        self.pytest_args = ''

    def run_tests(self):
        import shlex
        # import here, cause outside the eggs aren't loaded
        import pytest
        errno = pytest.main(shlex.split(self.pytest_args))
        sys.exit(errno)
# end of PyTest


"""
https://packaging.python.org/guides/making-a-pypi-friendly-readme/
check the README.rst works on pypi as the
long_description with:
twine check dist/*
"""
long_description = open('README.rst').read()

cur_path, cur_script = os.path.split(sys.argv[0])
os.chdir(os.path.abspath(cur_path))

install_requires = [
    'ansible',
    'colorlog',
    'coverage',
    'flake8<=3.4.1',
    'pep8>=1.7.1',
    'pipenv',
    'pycodestyle<=2.3.1',
    'pylint',
    'recommonmark',
    'sphinx',
    'sphinx-autobuild',
    'sphinx_rtd_theme',
    'spylunking',
    'unittest2',
    'mock'
]


if sys.version_info < (3, 5):
    warnings.warn(
        'Less than Python 3.5 is not supported.',
        DeprecationWarning)


# Do not import deploy_to_kubernetes_client module
# here, since deps may not be installed
sys.path.insert(
    0,
    os.path.join(
        os.path.dirname(__file__),
        'deploy_to_kubernetes'))

setup(
    name='deploy-to-kubernetes',
    cmdclass={'test': PyTest},
    version='1.0.4',
    description=(
        'Deployment tooling for managing '
        'a distributed AI stack on Kubernetes. Projects using '
        'this tool: '
        'AntiNex (https://antinex.readthedocs.io/en/latest/) '
        'and the Stock Analysis Engine ('
        'https://stock-analysis-engine.readthedocs.io/en/latest/) '
        'and works on Kubernetes 1.13.1'),
    long_description=long_description,
    author='Jay Johnson',
    author_email='jay.p.h.johnson@gmail.com',
    url='https://github.com/jay-johnson/deploy-to-kubernetes',
    packages=[
        'deploy_to_kubernetes',
        'deploy_to_kubernetes.scripts'
    ],
    package_data={},
    install_requires=install_requires,
    test_suite='setup.deploy_to_kubernetes',
    tests_require=[
        'pytest'
    ],
    scripts=[
    ],
    use_2to3=True,
    classifiers=[
        'Development Status :: 5 - Production/Stable',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: Apache Software License',
        'Operating System :: OS Independent',
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: Implementation :: PyPy',
        'Topic :: Software Development :: Libraries :: Python Modules',
    ])
