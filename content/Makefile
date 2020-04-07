.PHONY: draft public

all: draft

draft:
	git add . && git commit -am "draft" && git push

public:
	./deploy.sh
