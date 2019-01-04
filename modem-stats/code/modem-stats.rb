#!/usr/bin/env ruby

require 'mechanize'
require 'influxdb'
require 'dotenv'

class String
  def remove_html!
    self.gsub!(/<(\/)?[a-zA-Z]+>/, '')
  end
end

Dotenv.load
modem = {}

agent = Mechanize.new
home = ENV['ROUTER_URL']
data = {
  'admin_username' => ENV['ROUTER_USER'],
  'admin_password' => ENV['ROUTER_PASS']
}
agent.post(home + "/login.cgi", data)

# router table
res = agent.get(home + "/GetRouterTable.html")
router_table = res.body.split("$")

# modem resources
modem['resources'] = {
  'cpu_usage'      => router_table[0].to_f, # ProcessorUtilization: 3.00
  'mem_available'  => router_table[1].to_i, # SDRAMMemory: 512
  'mem_used'       => router_table[2].to_i, # SDRAMUsed: 36
  'mem_status'     => router_table[3], # MemoryStatus: <font>OK</font>
  'mem_recommend'  => router_table[4], # MemRecommended: <font>NONE</font>
  'flash_used'     => router_table[5].to_i  # FLASHUsed: 50
}
modem['resources']['mem_status'].remove_html!
modem['resources']['mem_recommend'].remove_html!

# modem sessions
modem['sessions'] = {
  'n_lan_tcp' => router_table[6].to_i,  # LanTCPSessions: 427
  'n_lan_udp' => router_table[7].to_i,  # LanUDPSessions: 636
  'n_modem'   => router_table[8].to_i,  # ModemSessions: 11
  'n_total'   => router_table[9].to_i,  # TotalSessions: 1074
  'n_max'     => router_table[10].to_i, # MaxNumSessions: 25180
  'status'    => router_table[11], # SessionStatus: <font>OK</font>
  'recommend' => router_table[12]  # SessionRecommended: <font>NONE</font>
}
modem['sessions']['status'].remove_html!
modem['sessions']['recommend'].remove_html!

# lan device log
lan_device_log = router_table[13].split("|").map{|e| e.split("/")}
lan_device_log.map! do |e|
  {:device     => e[0],     # iPhone
   :protocol   => e[1],     # TCP
   :destination_ip => e[2], # 8.8.8.8
   :sessions   => e[3].to_i,     # 1
   :packets_tx => e[4].to_i,     # 4
   :packets_rx => e[5].to_i}     # 4
end
modem['lan_device_log'] = lan_device_log

# write to influxdb
influxdb = InfluxDB::Client.new(ENV['DATABASE'], url: ENV['INFLUXDB_URL'])

data = [
  {
    series: 'resources',
    values: modem['resources']
  },
  {
    series: 'sessions',
    values: modem['sessions']
  }
]

influxdb.write_points(data)
