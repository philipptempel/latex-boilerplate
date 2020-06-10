#!/usr/bin/env python3

import sys
import click
import shutil
import re


@click.command()
@click.option('-o', '--output', type=click.File('w'), default=sys.stdout)
@click.argument('file', type=click.File('r'))
def finalizer(file, output):
    # read input
    fin = ''.join(file.readlines())

    # regexp object for finding the `documentclass` header
    reg = re.compile(r'documentclass(\[([\%a-zA-Z0-9=,\ \r\n]+)\])?{([a-zA-Z0-9\-_]+)}')
    # append "final" to the document class options
    fout = reg.sub(r'documentclass[\2final,%\n]{\3}', fin)
    
    # write output
    output.writelines(fout)


if __name__ == "__main__":
    finalizer()
