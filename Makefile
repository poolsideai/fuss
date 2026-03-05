mini:
	go build -o fuss_amd64 ./cmd/fuss; strip fuss_amd64; upx fuss_amd64

mini-cross-arm:
	GOARCH=arm64 go build -o fuss_arm64 ./cmd/fuss; aarch64-linux-gnu-strip fuss_arm64; upx fuss_arm64

build:
	go build ./cmd/fuss

clean:
	rm -f fuss
