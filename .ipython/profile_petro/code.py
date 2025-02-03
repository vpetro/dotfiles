import json

def read_json(filename: str):
    with open(filename, 'r') as f:
        return json.load(f)

def read_file(filename: str):
    with open(filename, 'r') as f:
        return f.read()

try:
    from lxml import html
except:
    pass

try:
    import pandas as pd
except:
    pass

try:
    import numpy as np
except:
    pass

try:
    import beautifulsoup4 as bs
except:
    pass

