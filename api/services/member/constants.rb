module MAPI
  module Services
    module Member
      module Constants
        ADVANCES_PAYMENT_FREQUENCY_MAPPING = {
            'D'=> 'Daily',
            'M'=> 'Monthly',
            'Q'=> 'Quarterly',
            'S'=> 'Semiannually',
            'A'=> 'Annually',
            'IAM'=> 'At Maturity',
            '4W'=> 'Every 4 weeks',
            '9W'=> 'Every 9 weeks',
            '13W'=> 'Every 13 weeks',
            '26W'=> 'Every 26 weeks',
            'ME'=> 'Monthend'
        }

        ADVANCES_DAY_COUNT_BASIS_MAPPING = {
            'BOND'=> '30/360',
            'A360'=> 'Actual/360',
            'A365'=> 'Actual/365',
            'ACT365'=> 'Actual/Actual',
            '30/360'=> '30/360',
            'ACT/360'=> 'Actual/360',
            'ACT/365'=> 'Actual/365',
            'ACT/ACT'=> 'Actual/Actual'
        }
      end
    end
  end
end