import os
import re

# Регулярное выражение для проверки домена:
# ^           - начало строки
# (?!.*[/:])  - негативное утверждение, запрещающее наличие символов "/" и ":"
# (?:[a-zA-Z0-9-]+\.)+ - одна или несколько групп, состоящих из букв, цифр или дефисов,
# за которыми следует точка
# [a-zA-Z]{2,} - доменная зона из минимум двух букв
# $           - конец строки

domain_regex = re.compile(r'^(?!.*[/:])(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$')


def check_file(filepath: str) -> None:
    with open(filepath, 'r', encoding='utf-8') as file:
        for line_num, line in enumerate(file, start=1):
            domain = line.strip()
            if not domain:
                continue
            if not domain_regex.match(domain):
                print(
                    f"Ошибка в файле '{filepath}' на строке {line_num}:"
                    f"'{domain}' не соответствует требованиям."
                )


def walk_directory(root_dir: str) -> None:
    for dirpath, dirnames, filenames in os.walk(root_dir):
        for filename in filenames:
            filepath = os.path.join(dirpath, filename)
            check_file(filepath)


if __name__ == '__main__':
    directory = os.getcwd() + '/domains'
    if os.path.isdir(directory):
        walk_directory(directory)
    else:
        print("Указанный путь не является директорией.")
