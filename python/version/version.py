#!/usr/bin/env python

"""
Repository version module
"""

import datetime
import subprocess
import re
import os.path


class RepositoryVersion(object):
    filename = '.version'
    repository_path = '/etc/btc_monitor/'

    def get_branch(self):
        command = 'echo `git log -n 1 --merges --pretty=format:"%s" '\
                  '| grep -E "(\'\w+\')$" -o | tail -1`'
        branch = subprocess.check_output(command, stderr=subprocess.PIPE,
                                         shell=True).decode('utf-8')

        return re.sub('\n|\'', '', branch)

    def get_version(self):
        try:
            branch = self.get_branch()

            if branch == 'dev':
                command = 'git log -1 --pretty=format:\'dev-g%h\n\''
            else:
                command = 'git describe --tags --dirty'

            tag = subprocess.check_output(command, stderr=subprocess.PIPE,
                                          shell=True).decode('utf-8')

        except subprocess.CalledProcessError:
            file = False

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
