require 'rails_helper'

describe HumanNameParser do
  it 'initializes' do
    expect(HumanNameParser.new('Tester')).to be_a HumanNameParser
  end

  describe '#parse' do
    it 'parses a name like "Bob Jones"' do
      expect(HumanNameParser.new('Bob Jones').parse).to eq(first_name: 'Bob',
                                                           middle_name: nil,
                                                           last_name: 'Jones',
                                                           spouse_first_name: nil,
                                                           spouse_middle_name: nil,
                                                           spouse_last_name: nil)
    end

    it 'parses a name like "Bob L. Jones"' do
      expect(HumanNameParser.new('Bob L. Jones').parse).to eq(first_name: 'Bob',
                                                              middle_name: 'L.',
                                                              last_name: 'Jones',
                                                              spouse_first_name: nil,
                                                              spouse_middle_name: nil,
                                                              spouse_last_name: nil)
    end

    it 'parses a name like "Bob Van Dyke"' do
      expect(HumanNameParser.new('Bob Van Dyke').parse).to eq(first_name: 'Bob',
                                                              middle_name: nil,
                                                              last_name: 'Van Dyke',
                                                              spouse_first_name: nil,
                                                              spouse_middle_name: nil,
                                                              spouse_last_name: nil)
    end

    it 'parses a name like "Jones, Bob"' do
      expect(HumanNameParser.new('Jones, Bob').parse).to eq(first_name: 'Bob',
                                                            middle_name: nil,
                                                            last_name: 'Jones',
                                                            spouse_first_name: nil,
                                                            spouse_middle_name: nil,
                                                            spouse_last_name: nil)
    end

    it 'parses a name like "Mr. Bob Billy Jones Sr."' do
      expect(HumanNameParser.new('Mr. Bob Billy Jones Sr.').parse).to eq(first_name: 'Bob',
                                                                         middle_name: 'Billy',
                                                                         last_name: 'Jones',
                                                                         spouse_first_name: nil,
                                                                         spouse_middle_name: nil,
                                                                         spouse_last_name: nil)
    end

    it 'parses names like "Jones, Bob and Sara"' do
      expect(HumanNameParser.new('Jones, Bob and Sara').parse).to eq(first_name: 'Bob',
                                                                     middle_name: nil,
                                                                     last_name: 'Jones',
                                                                     spouse_first_name: 'Sara',
                                                                     spouse_middle_name: nil,
                                                                     spouse_last_name: 'Jones')
    end

    it 'parses names like "Jones, Bob and ."' do
      expect(Rollbar).to_not receive(:info)
      expect(HumanNameParser.new('Jones, Bob and .').parse).to eq(first_name: 'Bob',
                                                                  middle_name: nil,
                                                                  last_name: 'Jones',
                                                                  spouse_first_name: '.',
                                                                  spouse_middle_name: nil,
                                                                  spouse_last_name: 'Jones')
    end

    it 'parses names like "Jones, Bob and ???"' do
      expect(Rollbar).to_not receive(:info)
      expect(HumanNameParser.new('Jones, Bob and ???').parse).to eq(first_name: 'Bob',
                                                                    middle_name: nil,
                                                                    last_name: 'Jones',
                                                                    spouse_first_name: '???',
                                                                    spouse_middle_name: nil,
                                                                    spouse_last_name: 'Jones')
    end

    it 'parses names like "Bob and Sara Jones"' do
      expect(HumanNameParser.new('Bob and Sara Jones').parse).to eq(first_name: 'Bob',
                                                                    middle_name: nil,
                                                                    last_name: 'Jones',
                                                                    spouse_first_name: 'Sara',
                                                                    spouse_middle_name: nil,
                                                                    spouse_last_name: 'Jones')
    end

    it 'parses names like "Bob and Sara Van Dyke"' do
      expect(HumanNameParser.new('Bob and Sara Van Dyke').parse).to eq(first_name: 'Bob',
                                                                       middle_name: nil,
                                                                       last_name: 'Van Dyke',
                                                                       spouse_first_name: 'Sara',
                                                                       spouse_middle_name: nil,
                                                                       spouse_last_name: 'Van Dyke')
    end

    it 'parses names like "Jones, Bob and Sara (Nickname)"' do
      expect(HumanNameParser.new('Jones, Bob and Sara (Nickname)').parse).to eq(first_name: 'Bob',
                                                                                middle_name: nil,
                                                                                last_name: 'Jones',
                                                                                spouse_first_name: 'Sara',
                                                                                spouse_middle_name: nil,
                                                                                spouse_last_name: 'Jones')
    end

    it 'parses names like "Jones, Bob (Nickname) and Sara"' do
      expect(HumanNameParser.new('Jones, Bob (Nickname) and Sara').parse).to eq(first_name: 'Bob',
                                                                                middle_name: nil,
                                                                                last_name: 'Jones',
                                                                                spouse_first_name: 'Sara',
                                                                                spouse_middle_name: nil,
                                                                                spouse_last_name: 'Jones')
    end

    it 'parses names like "Jones, Bob (Nickname) and Sara (Nickname)"' do
      expect(HumanNameParser.new('Jones, Bob (Nickname) and Sara (Nickname)').parse).to eq(first_name: 'Bob',
                                                                                           middle_name: nil,
                                                                                           last_name: 'Jones',
                                                                                           spouse_first_name: 'Sara',
                                                                                           spouse_middle_name: nil,
                                                                                           spouse_last_name: 'Jones')
    end

    it 'parses names like "Bob (Nickname) Jones"' do
      expect(HumanNameParser.new('Bob (Nickname) Jones').parse).to eq(first_name: 'Bob',
                                                                      middle_name: nil,
                                                                      last_name: 'Jones',
                                                                      spouse_first_name: nil,
                                                                      spouse_middle_name: nil,
                                                                      spouse_last_name: nil)
    end

    it 'parses names like "Bob Jones (Nickname)"' do
      expect(HumanNameParser.new('Bob Jones (Nickname)').parse).to eq(first_name: 'Bob',
                                                                      middle_name: nil,
                                                                      last_name: 'Jones',
                                                                      spouse_first_name: nil,
                                                                      spouse_middle_name: nil,
                                                                      spouse_last_name: nil)
    end

    it 'parses names like "Young Jae Lee and Kyung Soon Kim"' do
      expect(HumanNameParser.new('Young Jae Lee and Kyung Soon Kim').parse).to eq(first_name: 'Young',
                                                                                  middle_name: 'Jae',
                                                                                  last_name: 'Lee',
                                                                                  spouse_first_name: 'Kyung',
                                                                                  spouse_middle_name: 'Soon',
                                                                                  spouse_last_name: 'Kim')
    end

    it 'parses names like "Young Jae Kim and Kyung Soon"' do
      expect(HumanNameParser.new('Young Jae Kim and Kyung Soon').parse).to eq(first_name: 'Young',
                                                                              middle_name: 'Jae',
                                                                              last_name: 'Kim',
                                                                              spouse_first_name: 'Kyung',
                                                                              spouse_middle_name: 'Soon',
                                                                              spouse_last_name: 'Kim')
    end

    it 'parses names like "Young Jae and Kyung Soon Kim"' do
      expect(HumanNameParser.new('Young Jae and Kyung Soon Kim').parse).to eq(first_name: 'Young',
                                                                              middle_name: 'Jae',
                                                                              last_name: 'Kim',
                                                                              spouse_first_name: 'Kyung',
                                                                              spouse_middle_name: 'Soon',
                                                                              spouse_last_name: 'Kim')
    end

    it 'parses names like "Kim, Young Jae and Kyung Soon"' do
      expect(HumanNameParser.new('Kim, Young Jae and Kyung Soon').parse).to eq(first_name: 'Young',
                                                                               middle_name: 'Jae',
                                                                               last_name: 'Kim',
                                                                               spouse_first_name: 'Kyung',
                                                                               spouse_middle_name: 'Soon',
                                                                               spouse_last_name: 'Kim')
    end

    it 'parses names like "Jones, Bobby Bob and Sary, Sarah"' do
      expect(HumanNameParser.new('Jones, Bobby Bob and Sary, Sarah').parse).to eq(first_name: 'Bobby',
                                                                                  middle_name: 'Bob',
                                                                                  last_name: 'Jones',
                                                                                  spouse_first_name: 'Sarah',
                                                                                  spouse_middle_name: 'Sary',
                                                                                  spouse_last_name: 'Jones')
    end

    it %(parses names like "Bob and Sara Jones") do
      expect(HumanNameParser.new('Bob and Sara Jones').parse).to eq(first_name: 'Bob',
                                                                    middle_name: nil,
                                                                    last_name: 'Jones',
                                                                    spouse_first_name: 'Sara',
                                                                    spouse_middle_name: nil,
                                                                    spouse_last_name: 'Jones')
    end

    it %(parses names like "Mr. Bob Jones and Mrs. Sara Janes") do
      expect(HumanNameParser.new('Mr. Bob Jones and Mrs. Sara Janes').parse).to eq(first_name: 'Bob',
                                                                                   middle_name: nil,
                                                                                   last_name: 'Jones',
                                                                                   spouse_first_name: 'Sara',
                                                                                   spouse_middle_name: 'Janes',
                                                                                   spouse_last_name: 'Jones')
    end

    ['Mr. and Mrs.', 'Mr and Mrs', 'Mr. & Mrs.', 'Mrs. and Mr.', 'Miss & Mr'].each do |titles|
      it %(parses names like "#{titles} Bob and Sara") do
        expect(HumanNameParser.new("#{titles} Bob and Sara").parse).to eq(first_name: 'Bob',
                                                                          middle_name: nil,
                                                                          last_name: nil,
                                                                          spouse_first_name: 'Sara',
                                                                          spouse_middle_name: nil,
                                                                          spouse_last_name: nil)
      end

      it %(parses names like "#{titles} Bob and Sara Jones") do
        expect(HumanNameParser.new("#{titles} Bob and Sara Jones").parse).to eq(first_name: 'Bob',
                                                                                middle_name: nil,
                                                                                last_name: 'Jones',
                                                                                spouse_first_name: 'Sara',
                                                                                spouse_middle_name: nil,
                                                                                spouse_last_name: 'Jones')
      end

      it %(parses names like "#{titles} Jones, Bob and Sara") do
        expect(HumanNameParser.new("#{titles} Jones, Bob and Sara").parse).to eq(first_name: 'Bob',
                                                                                 middle_name: nil,
                                                                                 last_name: 'Jones',
                                                                                 spouse_first_name: 'Sara',
                                                                                 spouse_middle_name: nil,
                                                                                 spouse_last_name: 'Jones')
      end
    end

    it 'handles unparsable names' do
      expect(Nameable).to receive(:parse).and_raise(Nameable::InvalidNameError)

      expect(HumanNameParser.new('Unparsable Name').parse).to eq(first_name: nil,
                                                                 middle_name: nil,
                                                                 last_name: nil,
                                                                 spouse_first_name: nil,
                                                                 spouse_middle_name: nil,
                                                                 spouse_last_name: nil)
    end

    it 'notifies Rollbar if unparsable' do
      expect(Nameable).to receive(:parse).and_raise(Nameable::InvalidNameError)
      expect(Rollbar).to receive(:info)

      HumanNameParser.new('🎂').parse
    end
  end
end
