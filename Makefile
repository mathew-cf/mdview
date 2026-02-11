APP_NAME := MDView
BUNDLE   := build/$(APP_NAME).app
BIN_DIR  := .build/release
ICON_SRC := icon.png
ICON_OUT := build/AppIcon.icns
ICONSET  := build/AppIcon.iconset

.PHONY: all bundle icon install run clean

all: bundle

bundle: icon
	swift build -c release
	@mkdir -p "$(BUNDLE)/Contents/MacOS" "$(BUNDLE)/Contents/Resources"
	cp "$(BIN_DIR)/$(APP_NAME)" "$(BUNDLE)/Contents/MacOS/"
	cp -R "$(BIN_DIR)/MDView_MDView.bundle" "$(BUNDLE)/Contents/Resources/"
	cp Info.plist "$(BUNDLE)/Contents/"
	@if [ -f "$(ICON_OUT)" ]; then cp "$(ICON_OUT)" "$(BUNDLE)/Contents/Resources/"; fi
	codesign --force -s - "$(BUNDLE)"
	@echo "✓ $(BUNDLE) is ready"

icon:
	@mkdir -p build
	@if [ -f "$(ICON_SRC)" ]; then \
		rm -rf "$(ICONSET)" && mkdir -p "$(ICONSET)" && \
		sips -z   16   16 "$(ICON_SRC)" --out "$(ICONSET)/icon_16x16.png"      > /dev/null 2>&1 && \
		sips -z   32   32 "$(ICON_SRC)" --out "$(ICONSET)/icon_16x16@2x.png"   > /dev/null 2>&1 && \
		sips -z   32   32 "$(ICON_SRC)" --out "$(ICONSET)/icon_32x32.png"      > /dev/null 2>&1 && \
		sips -z   64   64 "$(ICON_SRC)" --out "$(ICONSET)/icon_32x32@2x.png"   > /dev/null 2>&1 && \
		sips -z  128  128 "$(ICON_SRC)" --out "$(ICONSET)/icon_128x128.png"    > /dev/null 2>&1 && \
		sips -z  256  256 "$(ICON_SRC)" --out "$(ICONSET)/icon_128x128@2x.png" > /dev/null 2>&1 && \
		sips -z  256  256 "$(ICON_SRC)" --out "$(ICONSET)/icon_256x256.png"    > /dev/null 2>&1 && \
		sips -z  512  512 "$(ICON_SRC)" --out "$(ICONSET)/icon_256x256@2x.png" > /dev/null 2>&1 && \
		sips -z  512  512 "$(ICON_SRC)" --out "$(ICONSET)/icon_512x512.png"    > /dev/null 2>&1 && \
		sips -z 1024 1024 "$(ICON_SRC)" --out "$(ICONSET)/icon_512x512@2x.png" > /dev/null 2>&1 && \
		iconutil -c icns "$(ICONSET)" -o "$(ICON_OUT)" && \
		rm -rf "$(ICONSET)" && \
		echo "✓ Icon created from $(ICON_SRC)"; \
	else \
		echo "⚠ No $(ICON_SRC) found — bundle will use default icon"; \
	fi

install: bundle
	cp -R "$(BUNDLE)" /Applications/
	@echo "✓ Installed to /Applications/$(APP_NAME).app"

run: bundle
	open "$(BUNDLE)"

clean:
	swift package clean
	rm -rf build
