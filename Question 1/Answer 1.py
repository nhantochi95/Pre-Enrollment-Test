# **Question 1**

# Write a Python function called def_word_cnt that takes in a string and returns a
# dictionary where the keys are the unique words in the string and the values are the counts
# of each word, and then write the result into JSON file name "result.json"?

# Example:
# Input: "hello world hello"
# Output: {'hello': 2, 'world': 1}

# Input: "data engineering is awesome"
# Output: {'data': 1, 'engineering': 1, 'is': 1, 'awesome': 1}

# Do not use looping in Python, generate 100 files result.json with name from
# result_1.json, result_2.json, ... result_100.json

import json
from collections import Counter

def def_word_cnt(text):
    # Đếm từ mà không sử dụng vòng lặp
    word_count = dict(Counter(text.split()))
    
    # Ghi kết quả vào file JSON
    with open('result.json', 'w') as f:
        json.dump(word_count, f)
    
    # Tạo 100 file JSON
    filenames = [f'result_{i}.json' for i in range(1, 101)]
    
    # Ghi dữ liệu vào các file này
    list(map(lambda filename: json.dump(word_count, open(filename, 'w')), filenames))

# Test
def_word_cnt("hello world hello")