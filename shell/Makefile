#---------------------------------------------------------------------------------
# Install & Uninstall
#---------------------------------------------------------------------------------

BTC_DIR:=/opt/btc_monitor
BTC_CONFIG:=/etc/btc_monitor

install:
	@echo Installing...
	@mkdir -p $(BTC_DIR) $(BTC_CONFIG)
	@cp -Rf *.sh media $(BTC_DIR)
	@mv $(BTC_DIR)/monitor.sh $(BTC_DIR)/btc_monitor
	@chmod +x $(BTC_DIR)/btc_monitor
	@ln -s $(BTC_DIR)/btc_monitor /usr/local/bin/btc_monitor
	@cp -f extras/btc_monitor/* $(BTC_CONFIG)
	@find $(BTC_CONFIG)/* -type f -exec sh -c 'cp -f {} {}.example' \;
	@echo Installation complete.
	
uninstall:
	@echo Uninstalling...
	@rm -rf /usr/local/bin/btc_monitor $(BTC_DIR)
	@echo Uninstallation complete.
