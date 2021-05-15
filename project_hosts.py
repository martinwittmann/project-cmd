import click
import python_hosts
from functools import reduce

def _filter_entries(entry, entry_type='ipv4', address=None):
    if entry.entry_type != entry_type:
        return False

    if address is None:
        return True

    return entry.address == address

class Hosts:
    def __init__(self):
        self._hosts = python_hosts.Hosts()

    def get_hosts_file_location(self):
        return self._hosts.hosts_path

    def get_localhost_hostnames(self, entry_type='ipv4', address='127.0.0.1'):
        entries = self.find_entries(entry_type=entry_type, address=address)
        hostnames = reduce(lambda result, l: result + l.names, entries, [])
        hostnames.sort()
        return hostnames

    def find_entries(self, entry_type, address=None, hostname=None):
        def _filter_entries(entry):
            if entry.entry_type != entry_type:
                return False

            if address is not None and entry.address != address:
                return False

            if hostname is not None and hostname not in entry.names:
                return False

            return True

        return filter(_filter_entries, self._hosts.entries)


    def add_hostname(self, entry_type, address, hostname):
        entries = list(self.find_entries(entry_type=entry_type, address=address))
        if len(entries) < 1:
            entry = python_hosts.HostsEntry(entry_type=entry_type, address=address,
                                            names=[hostname])
            self._hosts.add([entry])
        else:
            entry = entries[0]

        if hostname in entry.names:
            raise click.ClickException('The hostname "{}" was already added for address {}'
                                       .format(hostname, address))
        entry.names.append(hostname)
        self._hosts.write()

        return True


    def remove_hostname(self, entry_type, address, hostname):
        entries = list(self.find_entries(entry_type=entry_type, address=address))
        if len(entries) < 1:
            raise click.ClickException('No hosts entry found for address {}.'
                                       .format(address))
        else:
            entry = entries[0]

        if hostname in entry.names:
            entry.names.remove(hostname)
            self._hosts.write()
        else:
            raise click.ClickException('No entry found for hostname {}'
                                       .format(hostname))
        return True
