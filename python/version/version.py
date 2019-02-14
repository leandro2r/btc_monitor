#!/usr/bin/env python

"""
Repository version module
"""

import datetime
import subprocess
import re
import os


class RepositoryVersion(object):
    filename = '.version'
    repository_path = '/etc/btc_monitor/'

    def get_branch(self):
        # Gitlab CI_COMMIT_TAG and CI_COMMIT_REF_NAME variables
        if os.environ.get('CI_COMMIT_TAG'):
            branch = os.environ['CI_COMMIT_TAG']
        elif os.environ.get('CI_COMMIT_REF_NAME'):
            branch = os.environ['CI_COMMIT_REF_NAME']
        else:
            command = 'echo `git log -n 1 --merges \
                    --pretty=format:"%s" | tail -1`'
            branch = ''

            commit_msg = subprocess.check_output(
                command,
                stderr=subprocess.PIPE,
                shell=True,
            ).decode('utf-8').strip()

            if commit_msg:
                branch = re.search(r'(\S+)$', commit_msg).group(1)

            return re.sub('\'', '', branch)

    def get_version(self):
        command = 'git describe --tags --dirty'
        file = False

        try:
            branch = self.get_branch()

            if branch == 'dev':
                command = 'git log -1 --pretty=format:\'dev-g%h\n\''

            tag = subprocess.check_output(
                command,
                stderr=subprocess.PIPE,
                shell=True,
            ).decode('utf-8')
        except subprocess.CalledProcessError:
            try:
                file = open(self.filename, 'r')
            except IOError:
                try:
                    file = open(self.repository_path + self.filename, 'r')
                except IOError:
                    tag = 'dev'

            if file:
                tag = file.readline()
                file.close

        return tag

    def create_version_file(self, method=None):
        if not os.path.isfile(self.filename) or method == 'override':
            dist_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

            file = open(self.filename, 'w+')
            file.write(self.get_version() + 'Created at ' + dist_time + '\n')
            file.close

            print('The .version file has been created')
        else:
            print('The .version file already exists')

    def __version__(self):
        """
        Show the version
        """
        return re.match(r'\S[^-|\n]*', self.get_version()).group()


if __name__ == '__main__':
    print(RepositoryVersion().__version__())
