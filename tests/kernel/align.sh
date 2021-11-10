dd if=/dev/urandom of=random_4M.bin bs=1M count=4
dd if=kernel.bin of=random_4M.bin conv=notrunc