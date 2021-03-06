import sys

import os, errno
import time
import urllib
import xml.etree.ElementTree as etree

""" Quick and dirty script to get the texts as PDF files """


class GetTexts:

    def __init__(self):
        pass

    def get_text_filename(self, uri):
        """ Create the filename from the URI """
        tmp = uri.split("/")[-1]
        return tmp.replace('.xml', '.pdf')

    def get_pdf_file_process(self, host, workspace):

        """ Process the files and get the text """
        try:
            os.makedirs(os.path.dirname(workspace))
        except OSError as e:
            if e.errno != errno.EEXIST:
                raise
        url = host + '/api/texts.xql'
        xml_request = urllib.urlopen(url)
        tree = etree.parse(xml_request)
        root = tree.getroot()
        for child in root:
            text = child.attrib['uri']
            filename = self.get_text_filename(text)
            text_uri = host + '/t/' + filename
            print('Retrieving ' + text_uri)
            r = urllib.urlopen(text_uri)
            file_to_write = r'' + workspace + '/' + filename
            print(file_to_write)
            with open(file_to_write, 'wb') as file:
                file.write(r.read())
            # throttle
            time.sleep(3)


if __name__ == "__main__":
    GetTexts().get_pdf_file_process(sys.argv[1], sys.argv[2])