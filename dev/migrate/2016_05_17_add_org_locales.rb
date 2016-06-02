# This updates the organization locales based on the manually entered data
# below. I tracked the org id and name for the data entry but then wanted to
# run this on stage first and realized some ids would be different, so it
# looks by name and id (should have done it by query_ini_url).
def update_org_locales
  org_countries_and_locales.each do |org_id, org_name, country, locale|
    org = Organization.find_by(id: org_id)
    if org && org.name != org_name
      org_by_name = Organization.find_by(name: org_name)
      if org_by_name
        org = org_by_name
      else
        # This happens because my copy-paste to prod_console doesn't like
        # accented characters.
        puts "Organization name differs for id #{org_id}. "\
          "Expected #{org_name} but was #{org.name}"
      end
    else
      org = Organization.find_by(name: org_name)
    end
    unless org
      puts "Organization id #{org_id} and name #{org_name} not found"
      next
    end
    puts "Updating org #{org.name} (#{org.id}) "
    puts "  country from #{org.country} to #{country}"
    puts "  locale from #{org.locale} to #{locale}"
    org.update(country: country, locale: locale)
  end
  nil
end

# This is from data partially generated through the guess_org_country and
# guess_org_locale methods, but then reviewed and corrected by a person.
def org_countries_and_locales
  [
    [60, 'DonorElf', 'United States', 'en'],
    [5, 'Agape Leadership Dev - Surinam', 'Suriname', 'nl'],
    [81, 'Olive Branch International', 'United States', 'en'],
    [22, 'Campus Crusade for Christ - Canada (Intl.)', 'United States', 'en'],
    [6, 'Agapè Nederland', 'Netherlands', 'nl'],
    [2, 'Agape Europe AOA', 'United States', 'en'],
    [8, 'Agape Österreich - GAIN', 'Austria', 'de'],
    [15, 'Calvary International', 'United States', 'en'],
    [61, 'e3 Partners Ministry', 'United States', 'en'],
    [59, 'DiscipleMakers', 'United States', 'en'],
    [65, 'Food for the Hungry', 'United States', 'en'],
    [67, 'Global Hope Network International', 'United States', 'en'],
    [68, 'Global Impact Resources', 'United States', 'en'],
    [70, 'Gospel for Asia', 'United States', 'en'],
    [74, 'Kingdom Building Ministries', 'United States', 'en'],
    [62, 'Every Nation Ministries - Philippines', 'Philippines', 'tl'],
    [63, 'Every Nation Ministries - USA', 'United States', 'en'],
    [79, 'Novy zivot', 'Czech Republic', 'cs'],
    [80, 'Obra Social Agape', 'United States', 'en'],
    [77, 'Missions Door', 'United States', 'en'],
    [86, 'Tactical Chaplains Service', 'United States', 'en'],
    [93, 'Trinity Church - Dallas, TX', 'United States', 'en'],
    [95, 'Word Made Flesh', 'United States', 'en'],
    [97, 'YWAM Orlando', 'United States', 'en'],
    [1, 'Agape Bulgaria', 'Bulgaria', 'bg'],
    [14, 'Cadence International', 'United States', 'en'],
    [13, 'Asociatia Alege Viata Romania', 'Romania', 'ro'],
    [256, 'Hope of Glory', 'United States', 'en'],
    [31, 'Campus Crusade for Christ - Jamaica', 'Jamaica', 'en'],
    [37, 'Campus Crusade for Christ - Pacific Islands', 'United States', 'en'],
    [38, 'Campus Crusade for Christ - PNG', 'United States', 'en'],
    [52, 'CCO Canada', 'Canada', 'en'],
    [39, 'Campus Crusade for Christ - Russia', 'Russia', 'ru'],
    [71, 'Hesed Consulting', 'United States', 'en'],
    [88, 'The Impact Movement', 'United States', 'en'],
    [53, 'Cruzada Estudiantil - Costa Rica', 'Costa Rica', 'es'],
    [54, 'Cruzada Estudiantil - Dominican Republic', 'Dominican Republic', 'es'],
    [73, 'Instituti Jeta e Re', 'Albania', 'en'],
    [78, 'Nova Nadezh', 'Bulgaria', 'bg'],
    [75, 'Life Action Ministries', 'United States', 'en'],
    [142, 'Gospel For Asia USA', 'United States', 'en'],
    [87, 'Center for Mission Mobilization', 'United States', 'en'],
    [141, 'Gospel For Asia CAN', 'Canada', 'en'],
    [99, '306 Foundation', 'United States', 'en'],
    [3, 'Agape France', 'France', 'fr'],
    [149, 'Tandem Ministries - Family Life', 'New Zealand', 'en'],
    [64, 'FOCUS', 'United States', 'en'],
    [154, 'Kingdom Mobilization', 'United States', 'en'],
    [153, 'International Graduate School of Leadership (IGSL)', 'United States', 'en'],
    [271, 'Living Truth', 'United States', 'en'],
    [85, 'SIM USA', 'United States', 'en'],
    [98, 'Zoweh Ministries', 'United States', 'en'],
    [280, 'Ratio Christi', 'United States', 'en'],
    [7, 'Agape Österreich', 'Austria', 'de'],
    [4, 'Agape Greece', 'Greece', 'el'],
    [155, 'Living Waters Canada', 'Canada', 'en'],
    [157, 'The Navigators - South Africa', 'South Africa', 'af'],
    [294, 'Lutheran Bible Translators', 'United States', 'en'],
    [82, 'Perspectives', 'United States', 'en'],
    [148, 'Tandem Ministries', 'New Zealand', 'en'],
    [76, 'Mission Aviation Fellowship', 'United States', 'en'],
    [47, 'Campus Crusade for Christ - Trinidad', 'Trinidad', 'en'],
    [160, 'New Life Moldova', 'Moldova', 'ro'],
    [161, 'Ruch Nowego Zycia - POLAND', 'Poland', 'pl'],
    [265, 'Grace Ministries', 'United States', 'en'],
    [170, 'Agape Lithuania', 'Lithuania', 'lt'],
    [9, 'Agape Portugal', 'Portugal', 'pt_PT'],
    [169, 'Agape Ireland', 'Ireland', 'en'],
    [310, 'Reach Beyond', 'United States', 'en'],
    [10, 'Agape Spain', 'Spain', 'es_ES'],
    [334, 'Converge Worldwide', 'United States', 'en'],
    [324, 'Global Training Network', 'United States', 'en'],
    [44, 'Campus Crusade for Christ - Taiwan', 'Taiwan', 'zh'],
    [72, 'India Campus Crusade For Christ - Bangalore', 'India', 'hi'],
    [35, 'Campus Crusade for Christ - Nepal', 'Nepal', 'en'],
    [249, 'Agape Eesti', 'Estonia', 'et'],
    [214, 'Cross Trail Outfitters of Illinois', 'United States', 'en'],
    [94, 'UFC', 'United States', 'en'],
    [69, 'Global Service Network', 'United States', 'en'],
    [250, 'Be One Together', 'United States', 'en'],
    [211, 'Forest Springs', 'United States', 'en'],
    [213, 'SIM Canada', 'Canada', 'en'],
    [145, 'LA 2020', 'United States', 'en'],
    [146, 'Master Plan Ministries', 'United States', 'en'],
    [11, 'Agape UK', 'United Kingdom', 'en'],
    [1015, 'Eurasia Partners Network', 'United States', 'en'],
    [1358, 'SHIFT Ministries', 'United States', 'en'],
    [1359, 'Time To Revive', 'United States', 'en'],
    [1360, 'TntWare', 'United States', 'en'],
    [92, 'ToonTown Ministries', 'United States', 'en'],
    [96, 'Wycliffe Associates', 'United States', 'en'],
    [1362, 'Kingdom Rain', 'United States', 'en'],
    [1363, 'Storyline', 'United States', 'en'],
    [1364, 'LIFE MINISTRY ZIMBABWE', 'Zimbabwe', 'en'],
    [1357, 'e3 PARTNERS', 'United States', 'en'],
    [21, 'Campus Crusade for Christ - Canada', 'Canada', 'en'],
    [28, 'Campus Crusade for Christ - Guyana', 'Guyana', 'en'],
    [26, 'Campus Crusade for Christ - Fiji', 'Fiji', 'en'],
    [16, 'Campus Crusade for Christ - Argentina', 'Argentina', 'es'],
    [90, 'The Navigators - Canada', 'Canada', 'en'],
    [19, 'Campus Crusade for Christ - Bolivia', 'Bolivia', 'es'],
    [45, 'Campus Crusade for Christ - Thailand', 'Thailand', 'th'],
    [41, 'Campus Crusade for Christ - Solomon Islands', 'Solomon Islands', 'en'],
    [46, 'Campus Crusade for Christ - Tonga', 'Tonga', 'en'],
    [51, 'Campus fuer Christus e.V. - Germany', 'Germany', 'de'],
    [56, 'Cruzada Estudiantil - Guatemala', 'Guatemala', 'es'],
    [58, 'Cruzada Estudiantil - Mexico', 'Mexico', 'es'],
    [91, 'The Navigators - Singapore', 'Singapore', 'en'],
    [117, 'Campus Crusade for Christ - Mongolia', 'Mongolia', 'mn'],
    [152, 'Campus Crusade for Christ - Slovenia', 'Slovenia', 'sl'],
    [12, 'Alfa y Omega - Panama', 'Panama', 'es'],
    [18, 'Campus Crusade for Christ - Bangladesh', 'Bangladesh', 'bn'],
    [159, 'Campus Crusade for Christ - Philippines', 'Philippines', 'tl'],
    [43, 'Campus Crusade for Christ - Sri Lanka', 'Sri Lanka', 'si'],
    [20, 'Campus Crusade for Christ - Brasil', 'Brazil', 'pt'],
    [34, 'Campus Crusade for Christ - Latvia', 'Latvia', 'lv'],
    [32, 'Campus Crusade for Christ - Japan', 'Japan', 'ja'],
    [29, 'Campus Crusade for Christ - Hong Kong', 'Hong Kong', 'en'],
    [40, 'Cru - Singapore', 'Singapore', 'en'],
    [158, 'Campus Crusade for Christ - Ethiopia', 'Ethiopia', 'am'],
    [173, 'Campus Crusade for Christ - Sierra Leone', 'Sierra Leone', 'en'],
    [30, 'Campus Crusade for Christ - Italy', 'Italy', 'it'],
    [55, 'Cruzada Estudiantil - El Salvador', 'El Salvador', 'es'],
    [23, 'Campus Crusade for Christ - Chile', 'Chile', 'es'],
    [24, 'Campus Crusade for Christ - Colombia', 'Colombia', 'es'],
    [25, 'Campus Crusade for Christ - Ecuador', 'Ecuador', 'es'],
    [27, 'Campus Crusade for Christ - Ghana', 'Ghana', 'en'],
    [171, 'Campus Crusade for Christ - Liberia', 'Liberia', 'en'],
    [172, 'Campus Crusade for Christ - Nigeria', 'Nigeria', 'en'],
    [42, 'Campus Crusade for Christ - South Africa', 'South Africa', 'af'],
    [49, 'Campus Crusade for Christ - Venezuela', 'Venezuela', 'es'],
    [50, 'Campus Crusade for Christ - Zambia', 'Zambia', 'en'],
    [57, 'Cruzada Estudiantil - Honduras', 'Honduras', 'es'],
    [33, 'Campus Crusade for Christ - Kenya', 'Kenya', 'en'],
    [17, 'Power to Change - Australia', 'Australia', 'en'],
    [206, 'International Friendships, Inc (IFI)', 'United States', 'en'],
    [167, 'TeachBeyond - Canada', 'Canada', 'en'],
    [168, 'TeachBeyond - USA', 'United States', 'en'],
    [1365, 'The Global Mission', 'United States', 'en'],
    [156, 'United World Mission', 'United States', 'en'],
    [1368, 'University Christian Outreach', 'United States', 'en']
  ]
end
