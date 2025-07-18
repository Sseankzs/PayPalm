import React, { useState, useMemo } from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, AreaChart, Area, BarChart, Bar } from 'recharts';

export default function PalmPayProjections() {
  const [activeTab, setActiveTab] = useState('overview');
  const [selectedYear, setSelectedYear] = useState('all');

  // Generate 120 months of comprehensive financial projections
  const generateProjections = () => {
    const data = [];
    const months = 120;

    // Business Model Parameters 
    const feePercentage = 0.005; // 0.5% of transaction value
    const maxFeePerTransaction = 0.10; // Cap at RM 0.10 (10 cents)
    const minFeePerTransaction = 0.02; // Minimum RM 0.02 (2 cents)
    const averageTransactionSize = 30; // RM 30 average transaction
    
    // Calculate effective fee per transaction
    const calculateFee = (transactionAmount) => {
      const percentageFee = transactionAmount * feePercentage;
      return Math.min(Math.max(percentageFee, minFeePerTransaction), maxFeePerTransaction);
    };
    
    // For modeling purposes, use the average transaction size
    const effectiveFeePerTransaction = calculateFee(averageTransactionSize);
    
    // Growth Parameters
    for (let month = 1; month <= months; month++) {
    // S-Curve growth model: slow start, rapid middle, plateau at end
    let merchants;
    if (month <= 6) {
        // Slow start: 2-50 merchants in first 6 months
        merchants = Math.round(2 + (48 * (month - 1) / 5));
    } else if (month <= 60) {
        // Rapid growth phase: 50-8000 merchants months 7-60
        const progressThroughGrowth = (month - 6) / 54;
        merchants = Math.round(50 + (7950 * Math.pow(progressThroughGrowth, 1.5)));
    } else {
        // Mature phase: 8000-10000 merchants months 61-120
        const progressThroughMaturity = (month - 60) / 60;
        merchants = Math.round(8000 + (2000 * progressThroughMaturity));
    }
    const initialTransactionsPerMerchant = 1000;
    const finalTransactionsPerMerchant = 8000;
    
    // Cost Parameters
    const initialInfrastructureCost = 2000; // RM per month
    
    // Developer Team 
    const initialDeveloperCount = 3;
    const maxDeveloperCount = 10; // 
    const initialSalaryPerDev = 4000; // RM per month
    
    // Hardware Costs
    const hardwareCostPerMerchant = 200; // RM 200 average per merchant
    const hardwareAmortizationMonths = 12; // Amortized over 12 months
    
    // Marketing Team
    const initialMarketingTeam = 1;
    const maxMarketingTeam = 3; // 
    const initialMarketingSalary = 3500; // RM per person per month
    
    // Admin & Legal Team
    const initialAdminTeam = 1;
    const maxAdminTeam = 2; // 
    const initialAdminSalary = 4500; // RM per person per month
    
    // Operations Team
    const initialOpsTeam = 1; // Start with 1 ops staff
    const maxOpsTeam = 1; // 
    const initialOpsSalary = 3000; // RM per person per month
    
    
    let cumulativeProfit = 0;
    let previousMerchants = 0;
    
    for (let month = 1; month <= months; month++) {
      
      // Linear growth for transactions per merchant
      const transactionsPerMerchant = Math.round(
        initialTransactionsPerMerchant + 
        (finalTransactionsPerMerchant - initialTransactionsPerMerchant) * ((month - 1) / (months - 1))
      );
      
      const totalTransactions = merchants * transactionsPerMerchant;
      const revenue = totalTransactions * effectiveFeePerTransaction;
      
      // Infrastructure cost (30% annual growth, compounded monthly)
      const monthlyInfraGrowthRate = Math.pow(1.30, 1/12) - 1;
      const infrastructureCost = initialInfrastructureCost * Math.pow(1 + monthlyInfraGrowthRate, month - 1);
      
      // Developer team scaling 
      const developerCount = Math.round(
        initialDeveloperCount + 
        (maxDeveloperCount - initialDeveloperCount) * Math.pow((month - 1) / (months - 1), 0.7) // 
      );
      
      // Marketing team scaling
      const marketingTeamCount = Math.round(
        initialMarketingTeam + 
        (maxMarketingTeam - initialMarketingTeam) * Math.pow((month - 1) / (months - 1), 0.7)
      );
      
      // Admin team scaling  
      const adminTeamCount = Math.round(
        initialAdminTeam + 
        (maxAdminTeam - initialAdminTeam) * Math.pow((month - 1) / (months - 1), 0.7)
      );
      
      // Operations team scaling
      const opsTeamCount = Math.round(
        initialOpsTeam + 
        (maxOpsTeam - initialOpsTeam) * Math.pow((month - 1) / (months - 1), 0.7)
      );
      
      // Salary calculations with market increments (5% annually, compounded monthly)
      const monthlySalaryGrowthRate = Math.pow(1.05, 1/12) - 1;
      
      const salaryPerDev = initialSalaryPerDev * Math.pow(1 + monthlySalaryGrowthRate, month - 1);
      const salaryPerMarketing = initialMarketingSalary * Math.pow(1 + monthlySalaryGrowthRate, month - 1);
      const salaryPerAdmin = initialAdminSalary * Math.pow(1 + monthlySalaryGrowthRate, month - 1);
      const salaryPerOps = initialOpsSalary * Math.pow(1 + monthlySalaryGrowthRate, month - 1);
      
      // Total staff costs
      const totalDeveloperSalary = developerCount * salaryPerDev;
      const totalMarketingSalary = marketingTeamCount * salaryPerMarketing;
      const totalAdminSalary = adminTeamCount * salaryPerAdmin;
      const totalOpsSalary = opsTeamCount * salaryPerOps;
      
      // Hardware costs 
      const newMerchants = month === 1 ? merchants : merchants - previousMerchants;
      const hardwareCostThisMonth = (newMerchants * hardwareCostPerMerchant) / hardwareAmortizationMonths;
      
      // Additional operational costs (non-salary)
      const additionalMarketingCost = 2000; // Ad spend, tools, campaigns
      const additionalAdminCost = 1000; // Legal fees, accounting software, compliance
      const additionalUtilitiesCost = 800 + (Math.floor((developerCount + marketingTeamCount + adminTeamCount + opsTeamCount) / 5) * 300); // Office space scales with total team
      
      // Total costs
      const totalMonthlyCost = infrastructureCost + totalDeveloperSalary + totalMarketingSalary + 
                              totalAdminSalary + totalOpsSalary + hardwareCostThisMonth + 
                              additionalMarketingCost + additionalAdminCost + additionalUtilitiesCost;
      
      const netIncome = revenue - totalMonthlyCost;
      cumulativeProfit += netIncome;
      
        // Updated data object with new team structure
      data.push({
        month,
        year: Math.ceil(month / 12),
        merchants,
        newMerchants,
        transactionsPerMerchant,
        totalTransactions,
        revenue: Math.round(revenue),
        infrastructureCost: Math.round(infrastructureCost),
        
        // Developer team 
        developerCount,
        salaryPerDev: Math.round(salaryPerDev),
        totalDeveloperSalary: Math.round(totalDeveloperSalary),
        
        // Marketing team 
        marketingTeamCount,
        salaryPerMarketing: Math.round(salaryPerMarketing),
        totalMarketingSalary: Math.round(totalMarketingSalary),
        
        // Admin team 
        adminTeamCount,
        salaryPerAdmin: Math.round(salaryPerAdmin),
        totalAdminSalary: Math.round(totalAdminSalary),
        
        // Operations team 
        opsTeamCount,
        salaryPerOps: Math.round(salaryPerOps),
        totalOpsSalary: Math.round(totalOpsSalary),
        
        // Hardware and additional costs
        hardwareCostThisMonth: Math.round(hardwareCostThisMonth),
        additionalMarketingCost,
        additionalAdminCost,
        additionalUtilitiesCost: Math.round(additionalUtilitiesCost),
        
        // Legacy fields for backward compatibility
        marketingCost: Math.round(totalMarketingSalary + additionalMarketingCost),
        adminCost: Math.round(totalAdminSalary + additionalAdminCost),
        utilitiesCost: Math.round(totalOpsSalary + additionalUtilitiesCost),
        
        totalMonthlyCost: Math.round(totalMonthlyCost),
        netIncome: Math.round(netIncome),
        cumulativeProfit: Math.round(cumulativeProfit)
      });
      previousMerchants = merchants;
    }
    return data;
  };

  const allData = useMemo(() => generateProjections(), []);
  const filteredData = useMemo(() => {
    if (selectedYear === 'all') return allData;
    const yearNum = parseInt(selectedYear);
    return allData.filter(item => item.year === yearNum);
  }, [allData, selectedYear]);

  // Find break-even month
  const breakEvenMonth = allData.findIndex(item => item.netIncome >= 0);
  const breakEvenData = breakEvenMonth >= 0 ? allData[breakEvenMonth] : null;

  // Key metrics
  const finalMetrics = allData[allData.length - 1];
  const totalCumulativeProfit = finalMetrics.cumulativeProfit;
  const finalMonthlyRevenue = finalMetrics.revenue;
  const finalMonthlyProfit = finalMetrics.netIncome;

  return (
    <div className="flex flex-col space-y-6 p-6 bg-gray-50 min-h-screen">
      <div className="bg-white p-6 rounded-lg shadow-lg">
        <h1 className="text-3xl font-bold text-center text-blue-800 mb-2">PalmPay Financial Projections</h1>
        <p className="text-center text-gray-600 mb-4">10-Year Palm Biometric Payment Gateway Analysis</p>
        
        {/* Key Metrics Summary */}
        <div className="grid grid-cols-1 md:grid-cols-5 gap-4 mb-6">
          <div className="bg-gradient-to-r from-blue-500 to-blue-600 text-white p-4 rounded-lg">
            <h3 className="text-sm font-medium">Break-Even</h3>
            <p className="text-2xl font-bold">Month {breakEvenMonth >= 0 ? breakEvenMonth + 1 : 'N/A'}</p>
            <p className="text-sm opacity-90">
              {breakEvenData ? `${breakEvenData.merchants.toLocaleString()} merchants` : 'Never achieved'}
            </p>
          </div>
          <div className="bg-gradient-to-r from-green-500 to-green-600 text-white p-4 rounded-lg">
            <h3 className="text-sm font-medium">Final Monthly Revenue</h3>
            <p className="text-2xl font-bold">RM {finalMonthlyRevenue.toLocaleString()}</p>
            <p className="text-sm opacity-90">Month 120</p>
          </div>
          <div className="bg-gradient-to-r from-purple-500 to-purple-600 text-white p-4 rounded-lg">
            <h3 className="text-sm font-medium">Final Monthly Profit</h3>
            <p className="text-2xl font-bold">RM {finalMonthlyProfit.toLocaleString()}</p>
            <p className="text-sm opacity-90">Month 120</p>
          </div>
          <div className="bg-gradient-to-r from-orange-500 to-orange-600 text-white p-4 rounded-lg">
            <h3 className="text-sm font-medium">Final Team Size</h3>
            <p className="text-2xl font-bold">{finalMetrics.developerCount} Devs</p>
            <p className="text-sm opacity-90">RM {finalMetrics.salaryPerDev.toLocaleString()}/dev/month</p>
          </div>
          <div className="bg-gradient-to-r from-indigo-500 to-indigo-600 text-white p-4 rounded-lg">
            <h3 className="text-sm font-medium">10-Year Cumulative</h3>
            <p className="text-2xl font-bold">RM {totalCumulativeProfit.toLocaleString()}</p>
            <p className="text-sm opacity-90">{totalCumulativeProfit >= 0 ? 'Total Profit' : 'Total Loss'}</p>
          </div>
        </div>
      </div>

      {/* Controls */}
      <div className="bg-white p-4 rounded-lg shadow-md">
        <div className="flex flex-wrap justify-center gap-2 mb-4">
          <button 
            className={`px-4 py-2 rounded ${activeTab === 'overview' ? 'bg-blue-600 text-white' : 'bg-gray-200'}`}
            onClick={() => setActiveTab('overview')}
          >
            Revenue vs Costs
          </button>
          <button 
            className={`px-4 py-2 rounded ${activeTab === 'costs' ? 'bg-blue-600 text-white' : 'bg-gray-200'}`}
            onClick={() => setActiveTab('costs')}
          >
            Cost Breakdown
          </button>
          <button 
            className={`px-4 py-2 rounded ${activeTab === 'profit' ? 'bg-blue-600 text-white' : 'bg-gray-200'}`}
            onClick={() => setActiveTab('profit')}
          >
            Profitability
          </button>
          <button 
            className={`px-4 py-2 rounded ${activeTab === 'table' ? 'bg-blue-600 text-white' : 'bg-gray-200'}`}
            onClick={() => setActiveTab('table')}
          >
            Data Table
          </button>
        </div>
        
        <div className="flex justify-center">
          <select 
            value={selectedYear} 
            onChange={(e) => setSelectedYear(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-md"
          >
            <option value="all">All 10 Years</option>
            {[1,2,3,4,5,6,7,8,9,10].map(year => (
              <option key={year} value={year}>Year {year}</option>
            ))}
          </select>
        </div>
      </div>

      {/* Charts */}
      <div className="bg-white p-6 rounded-lg shadow-md">
        <div className="h-96 w-full">
          {activeTab === 'overview' && (
            <ResponsiveContainer>
              <LineChart data={filteredData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis 
                  dataKey="month" 
                  label={{ value: 'Month', position: 'insideBottom', offset: -5 }} 
                />
                <YAxis 
                  label={{ value: 'Amount (RM)', angle: -90, position: 'insideLeft' }} 
                />
                <Tooltip formatter={(value) => `RM ${value.toLocaleString()}`} />
                <Legend />
                <Line type="monotone" dataKey="revenue" stroke="#22c55e" strokeWidth={2} name="Monthly Revenue" />
                <Line type="monotone" dataKey="totalMonthlyCost" stroke="#ef4444" strokeWidth={2} name="Total Monthly Cost" />
                <Line type="monotone" dataKey="netIncome" stroke="#3b82f6" strokeWidth={2} name="Net Income" />
              </LineChart>
            </ResponsiveContainer>
          )}
          
          {activeTab === 'costs' && (
            <ResponsiveContainer>
              <AreaChart data={filteredData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis 
                  dataKey="month" 
                  label={{ value: 'Month', position: 'insideBottom', offset: -5 }} 
                />
                <YAxis 
                  label={{ value: 'Cost (RM)', angle: -90, position: 'insideLeft' }} 
                />
                <Tooltip formatter={(value) => `RM ${value.toLocaleString()}`} />
                <Legend />
                <Area type="monotone" dataKey="infrastructureCost" stackId="1" stroke="#8884d8" fill="#8884d8" name="Infrastructure" />
                <Area type="monotone" dataKey="totalDeveloperSalary" stackId="1" stroke="#82ca9d" fill="#82ca9d" name="Developer Salaries" />
                <Area type="monotone" dataKey="hardwareCostThisMonth" stackId="1" stroke="#ffc658" fill="#ffc658" name="Hardware (Amortized)" />
                <Area type="monotone" dataKey="marketingCost" stackId="1" stroke="#ff7300" fill="#ff7300" name="Marketing" />
                <Area type="monotone" dataKey="adminCost" stackId="1" stroke="#8dd1e1" fill="#8dd1e1" name="Admin & Legal" />
                <Area type="monotone" dataKey="utilitiesCost" stackId="1" stroke="#d084d0" fill="#d084d0" name="Utilities & Misc" />
              </AreaChart>
            </ResponsiveContainer>
          )}
          
          {activeTab === 'profit' && (
            <ResponsiveContainer>
              <AreaChart data={filteredData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis 
                  dataKey="month" 
                  label={{ value: 'Month', position: 'insideBottom', offset: -5 }} 
                />
                <YAxis 
                  label={{ value: 'Profit (RM)', angle: -90, position: 'insideLeft' }} 
                />
                <Tooltip formatter={(value) => `RM ${value.toLocaleString()}`} />
                <Legend />
                <Area type="monotone" dataKey="cumulativeProfit" stroke="#fbbf24" fill="#fbbf24" fillOpacity={0.6} name="Cumulative Profit" />
                <Line type="monotone" dataKey="netIncome" stroke="#3b82f6" strokeWidth={2} name="Monthly Net Income" />
              </AreaChart>
            </ResponsiveContainer>
          )}
        </div>
      </div>

      {/* Data Table */}
      {activeTab === 'table' && (
        <div className="bg-white p-6 rounded-lg shadow-md">
          <h3 className="text-lg font-bold mb-4">Monthly Financial Data</h3>
          <div className="overflow-x-auto max-h-96">
            <table className="min-w-full table-auto text-sm">
              <thead className="bg-gray-100 sticky top-0">
                <tr>
                  <th className="px-2 py-2 text-left">Month</th>
                  <th className="px-2 py-2 text-left">Merchants</th>
                  <th className="px-2 py-2 text-left">Trans/Merch</th>
                  <th className="px-2 py-2 text-left">Total Trans</th>
                  <th className="px-2 py-2 text-left">Revenue</th>
                  <th className="px-2 py-2 text-left">Infra Cost</th>
                  <th className="px-2 py-2 text-left">Dev Team</th>
                  <th className="px-2 py-2 text-left">Dev Cost</th>
                  <th className="px-2 py-2 text-left">Hardware</th>
                  <th className="px-2 py-2 text-left">Marketing</th>
                  <th className="px-2 py-2 text-left">Total Cost</th>
                  <th className="px-2 py-2 text-left">Net Income</th>
                  <th className="px-2 py-2 text-left">Cumulative</th>
                </tr>
              </thead>
              <tbody>
                {filteredData.map((row) => (
                  <tr key={row.month} className={row.netIncome >= 0 ? 'bg-green-50' : 'bg-red-50'}>
                    <td className="px-2 py-1">{row.month}</td>
                    <td className="px-2 py-1">{row.merchants.toLocaleString()}</td>
                    <td className="px-2 py-1">{row.transactionsPerMerchant.toLocaleString()}</td>
                    <td className="px-2 py-1">{row.totalTransactions.toLocaleString()}</td>
                    <td className="px-2 py-1">RM {row.revenue.toLocaleString()}</td>
                    <td className="px-2 py-1">RM {row.infrastructureCost.toLocaleString()}</td>
                    <td className="px-2 py-1">{row.developerCount}</td>
                    <td className="px-2 py-1">RM {row.totalDeveloperSalary.toLocaleString()}</td>
                    <td className="px-2 py-1">RM {row.hardwareCostThisMonth.toLocaleString()}</td>
                    <td className="px-2 py-1">RM {row.marketingCost.toLocaleString()}</td>
                    <td className="px-2 py-1">RM {row.totalMonthlyCost.toLocaleString()}</td>
                    <td className={`px-2 py-1 font-medium ${row.netIncome >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                      RM {row.netIncome.toLocaleString()}
                    </td>
                    <td className={`px-2 py-1 font-medium ${row.cumulativeProfit >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                      RM {row.cumulativeProfit.toLocaleString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Comprehensive Analysis Summary */}
      <div className="bg-white p-6 rounded-lg shadow-md">
        <h3 className="text-xl font-bold mb-4 text-blue-800">Comprehensive Financial Analysis</h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <h4 className="font-bold text-lg mb-2 text-gray-800">Key Assumptions Used</h4>
            <ul className="space-y-1 text-sm text-gray-700">
              <li><strong>Growth Model:</strong> Linear scaling for both merchants (100→10,000) and transactions/merchant (1,000→8,000)</li>
              <li><strong>Fee Structure:</strong> RM 0.02 per transaction (minimum fee applies due to RM 30 average transaction size)</li>
              <li><strong>Developer Scaling:</strong> Option B - Linear headcount growth (3→20) with 5% annual salary increases</li>
              <li><strong>Hardware Cost:</strong> RM 200 per merchant, amortized over 12 months for new merchants only</li>
              <li><strong>Infrastructure:</strong> 30% annual growth (compounded monthly)</li>
              <li><strong>Additional Costs:</strong> Marketing (RM 5,000), Admin (RM 3,000), Utilities (RM 1,500) monthly</li>
            </ul>
          </div>
          
          <div>
            <h4 className="font-bold text-lg mb-2 text-gray-800">Business Performance Summary</h4>
            <div className="space-y-2 text-sm text-gray-700">
              <p><strong>Break-Even:</strong> {breakEvenMonth >= 0 ? `Month ${breakEvenMonth + 1}` : 'Not achieved within 10 years'}</p>
              <p><strong>Peak Monthly Revenue:</strong> RM {finalMonthlyRevenue.toLocaleString()} (Month 120)</p>
              <p><strong>Peak Monthly Profit:</strong> RM {finalMonthlyProfit.toLocaleString()} (Month 120)</p>
              <p><strong>10-Year Cumulative:</strong> RM {totalCumulativeProfit.toLocaleString()} {totalCumulativeProfit >= 0 ? 'profit' : 'loss'}</p>
              <p><strong>Final Team Size:</strong> {finalMetrics.developerCount} developers at RM {finalMetrics.salaryPerDev.toLocaleString()}/month each</p>
            </div>
          </div>
        </div>
        
        <div className="mt-6 space-y-3 text-gray-700">
          <p>
            <strong>Growth Trajectory:</strong> Linear merchant and transaction growth drives revenue from RM {allData[0].revenue.toLocaleString()} to RM {finalMonthlyRevenue.toLocaleString()} monthly over 10 years.
          </p>
          <p>
            <strong>Cost Structure Impact:</strong> Developer salaries and infrastructure are the largest costs, scaling with business growth; fixed operational costs remain steady.
          </p>
          <p>
            <strong>Break-Even Analysis:</strong> {breakEvenMonth >= 0
              ? `Profitability reached in Month ${breakEvenMonth + 1} with ${breakEvenData.merchants.toLocaleString()} merchants.`
              : 'Break-even not achieved within 10 years due to high scaling costs.'}
          </p>
          <p>
            <strong>Long-term Viability:</strong> {totalCumulativeProfit >= 0
              ? `Cumulative profit of RM ${totalCumulativeProfit.toLocaleString()} over 10 years.`
              : `Cumulative loss of RM ${Math.abs(totalCumulativeProfit).toLocaleString()} over 10 years; consider adjusting fees or costs.`}
          </p>
        </div>
      </div>
    </div>
  );
}