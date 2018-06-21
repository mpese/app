import sys

import os, errno
import time
import urllib
import xml.etree.ElementTree as etree

""" Quick and dirty script to get the texts as text files """


class GetTexts:

    def __init__(self):
        pass

    def get_text_filename(self, uri):
        """ Create the filename from the URI """
        tmp = uri.split("/")[-1]
        return tmp.replace('.xml', '.simple.xml')

    def get_xml_file_process(self, host, workspace):
        """ Process the files and get the text """
        try:
            os.makedirs(os.path.dirname(workspace))
        except OSError as e:
            if e.errno != errno.EEXIST:
                raise
        url = host + '/modules/mpese-text-all.xql'
        xml_request = urllib.urlopen(url)
        tree = etree.parse(xml_request)
        root = tree.getroot()
        for child in root:
            text = child.attrib['uri']
            filename = self.get_text_filename(text)
            text_uri = host + '/t/' + filename
            print('Retrieving ' + text_uri)
            r = urllib.urlopen(text_uri)
            with open(workspace + '/' + filename, 'wb') as file:
                file.write(r.read())
            # throttle
            time.sleep(0.2)


if __name__ == "__main__":
    GetTexts().get_xml_file_process(sys.argv[1], sys.argv[2])
    # print(sys.argv[2])