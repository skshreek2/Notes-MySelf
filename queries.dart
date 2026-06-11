return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      
      children: [
        Text(
          'Good Morning Trisha!',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: textDark,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),


        Container(
          // padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 1),
            color: const Color.fromRGBO(255, 255, 255, 0.40),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFilter,
              borderRadius: BorderRadius.circular(12),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1.5,
              ),


              items: filters.map((f) {
                return DropdownMenuItem<String>(value: f, child: Text(f));
              }).toList(),
              onChanged: (String? value) {
                if (value == null || _selectedFilter == value) return;


                setState(() {
                  _selectedFilter = value;
                });


                final dateRange = DateRangeHelper.getDateRange(value);
                final fromDate = dateRange.fromDate;
                final toDate = dateRange.toDate;


                _paymentAnalyticsBloc.add(
                  LoadPaymentAnalytics(fromDate: fromDate, toDate: toDate),
                );
              },
            ),
          ),
        ),
],
);

How to know children aligned horizontally 
