f = open('build_number.txt', 'rb+')
build_number = int(f.readline())
f.seek(0)
f.write(str(build_number +1))
f.close()
