BANK = {}

BANK.PlayersRequired = 6 -- Players required to start a bank robbery.
BANK.PoliceRequired = 3 -- Police required to start a bank robbery.
BANK.BankersRequired = 1 -- Bankers required to start a bank robbery.

BANK.RobberyTime = 2 -- Minutes to complete a robbery.
BANK.RobberyDistance = 2000 -- Distance you must travel from bank to complete the robbery or leave it early.

BANK.AddMoneyAmount = 1250 -- Amount of money to add at a time.
BANK.AddMoneyDelay = 60 -- Delay in seconds between money being added to the bank, does not function while its being robbed.
BANK.MoneyMin = 6250 -- Minimum money required to start a robbery, functions as a cooldown of sorts.
BANK.MoneyMax = 20000 -- Maximum money that can be in the bank. Can be 0 for no limit.

BANK.BankerSalaryAddition = 1200 -- Amount of money a bankers salary will increase by to based on how full the bank is. Configure which jobs are bankers by doing "banker = true" in your job.

BANK.NotifyPolice = false -- Notifies police and bankers and bankers employees on robbery start.