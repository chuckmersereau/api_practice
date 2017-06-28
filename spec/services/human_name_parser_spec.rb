require 'rails_helper'

describe HumanNameParser do
  it 'initializes' do
    expect(HumanNameParser.new('Tester')).to be_a HumanNameParser
  end

  describe '#parse' do
    it 'parses a name like "Bob Jones"' do
      expect(HumanNameParser.new('Bob Jones').parse).to eq(first_name: 'Bob',
                                                           last_name: 'Jones',
                                                           spouse_first_name: nil,
                                                           spouse_last_name: nil)
    end

    it 'parses a name like "Bob L. Jones"' do
      expect(HumanNameParser.new('Bob L. Jones').parse).to eq(first_name: 'Bob',
                                                              last_name: 'Jones',
                                                              spouse_first_name: nil,
                                                              spouse_last_name: nil)
    end

    it 'parses a name like "Bob Van Dyke"' do
      expect(HumanNameParser.new('Bob Van Dyke').parse).to eq(first_name: 'Bob',
                                                              last_name: 'Van Dyke',
                                                              spouse_first_name: nil,
                                                              spouse_last_name: nil)
    end

    it 'parses a name like "Jones, Bob"' do
      expect(HumanNameParser.new('Jones, Bob').parse).to eq(first_name: 'Bob',
                                                            last_name: 'Jones',
                                                            spouse_first_name: nil,
                                                            spouse_last_name: nil)
    end

    it 'parses a name like "Mr. Bob Billy Jones Sr."' do
      expect(HumanNameParser.new('Mr. Bob Billy Jones Sr.').parse).to eq(first_name: 'Bob',
                                                                         last_name: 'Jones',
                                                                         spouse_first_name: nil,
                                                                         spouse_last_name: nil)
    end

    it 'parses names like "Jones, Bob and Sara"' do
      expect(HumanNameParser.new('Jones, Bob and Sara').parse).to eq(first_name: 'Bob',
                                                                     last_name: 'Jones',
                                                                     spouse_first_name: 'Sara',
                                                                     spouse_last_name: 'Jones')
    end

    it 'parses names like "Bob and Sara Jones"' do
      expect(HumanNameParser.new('Bob and Sara Jones').parse).to eq(first_name: 'Bob',
                                                                    last_name: 'Jones',
                                                                    spouse_first_name: 'Sara',
                                                                    spouse_last_name: 'Jones')
    end

    it 'parses names like "Bob and Sara Van Dyke"' do
      expect(HumanNameParser.new('Bob and Sara Van Dyke').parse).to eq(first_name: 'Bob',
                                                                       last_name: 'Van Dyke',
                                                                       spouse_first_name: 'Sara',
                                                                       spouse_last_name: 'Van Dyke')
    end

    context 'couple names' do
      it %(parses names like "Bob and Sara Jones") do
        expect(HumanNameParser.new('Bob and Sara Jones').parse).to eq(first_name: 'Bob',
                                                                      last_name: 'Jones',
                                                                      spouse_first_name: 'Sara',
                                                                      spouse_last_name: 'Jones')
      end

      it %(parses names like "Mr. Bob Jones and Mrs. Sara Janes") do
        expect(HumanNameParser.new('Mr. Bob Jones and Mrs. Sara Janes').parse).to eq(first_name: 'Bob',
                                                                                     last_name: 'Jones',
                                                                                     spouse_first_name: 'Sara',
                                                                                     spouse_last_name: 'Janes')
      end

      ['Mr. and Mrs.', 'Mr and Mrs', 'Mr. & Mrs.', 'Mrs. and Mr.', 'Miss & Mr'].each do |titles|
        it %(parses names like "#{titles} Bob and Sara") do
          expect(HumanNameParser.new("#{titles} Bob and Sara").parse).to eq(first_name: 'Bob',
                                                                            last_name: nil,
                                                                            spouse_first_name: 'Sara',
                                                                            spouse_last_name: nil)
        end

        it %(parses names like "#{titles} Bob and Sara Jones") do
          expect(HumanNameParser.new("#{titles} Bob and Sara Jones").parse).to eq(first_name: 'Bob',
                                                                                  last_name: 'Jones',
                                                                                  spouse_first_name: 'Sara',
                                                                                  spouse_last_name: 'Jones')
        end

        it %(parses names like "#{titles} Jones, Bob and Sara") do
          expect(HumanNameParser.new("#{titles} Jones, Bob and Sara").parse).to eq(first_name: 'Bob',
                                                                                   last_name: 'Jones',
                                                                                   spouse_first_name: 'Sara',
                                                                                   spouse_last_name: 'Jones')
        end
      end
    end
  end
end
