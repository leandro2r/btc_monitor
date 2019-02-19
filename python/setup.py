#!/usr/bin/env python

"""
BTC Monitor Setup
"""

from setuptools import find_packages, setup
from setuptools.command.sdist import sdist
from setuptools.command.install import install
from version.version import RepositoryVersion


class CustomInstall(install):
    def __init__(self, *args, **kwargs):
        RepositoryVersion().create_version_file()
        super().__init__(*args, **kwargs)


class CustomSdist(sdist):
    def run(self):
        RepositoryVersion().create_version_file('override')
        sdist.run(self)


dev_requirements = [
    'pylint==1.8',
    'flake8==3.3.0',
]

setup(
    name='btc_monitor',
    version=RepositoryVersion().__version__(),
    packages=find_packages(),
    include_package_data=True,
    zip_safe=False,
    install_requires=[
        'PyYaml',
        'requests',
        'vext.gi',
        'websocket-client',
    ],
    extras_require={
        'dev': dev_requirements
    },
    data_files=[('.', ['.version'])],
    entry_points={
        'console_scripts': [
            'btc_monitor=btc_monitor.main:main',
        ],
    },
    platforms='any',
    cmdclass={
        'install': CustomInstall,
        'sdist': CustomSdist,
    },
    classifiers=[
        'Environment :: Console',
        'Natural Language :: English',
        'Programming Language :: Python :: 3.7',
    ],
    keywords=[],
    url='https://github.com/leandro2r/btc_monitor',
    license='No license',
    author='leandro2r',
    author_email='leandro2r@gmail.com',
    description='BTC Monitor Script',
)
