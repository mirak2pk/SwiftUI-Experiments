    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                // MARK: - Sticky Blurred Home Flag Background
                if let flagAsset = homeCountryFlag {
                    Image(flagAsset)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: 400)
                        .scaleEffect(1.5)
                        .blur(radius: 50)
                        .opacity(0.25)
                        .clipped()
                        .overlay {
                            LinearGradient(
                                colors: [
                                    PassportTheme.background.opacity(0),
                                    PassportTheme.background
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                        .ignoresSafeArea()
                }
                
                // MARK: - Main Content
                ScrollView {
                    LazyVStack(spacing: PassportTheme.Spacing.xl) {
                        // Home badge
                     
                        
                        // Aviation Stats Header
                        statsHeader
                        
                        top10CountriesBar
                        
                        // Continents
                        ForEach(continents) { continent in
                            LazyVStack(alignment: .leading, spacing: PassportTheme.Spacing.md) {
                                
                                // Continent header with coverage
                                HStack {
                                    Text(continent.name)
                                        .font(PassportTheme.Typography.titleLarge)
                                        .foregroundStyle(PassportTheme.textPrimary)

                                    Spacer()

                                    let visited = visitedCount(in: continent)
                                    let total = continent.countries.count
                                    let percentage = total > 0 ? Int((Double(visited) / Double(total)) * 100) : 0

                                    Text("(\(visited)/\(total)) \(percentage)%")
                                        .font(PassportTheme.Typography.body)
                                        .foregroundStyle(PassportTheme.textSecondary)
                                }
                                
                                // Countries grid
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: PassportTheme.Spacing.md),
                                    GridItem(.flexible(), spacing: PassportTheme.Spacing.md),
                                    GridItem(.flexible(), spacing: PassportTheme.Spacing.md)
                                ], spacing: PassportTheme.Spacing.md) {
                                    ForEach(continent.countries.sorted {
                                        let aVisited = isVisited($0.code)
                                        let bVisited = isVisited($1.code)
                                        if aVisited != bVisited {
                                            return aVisited
                                        }
                                        return $0.name < $1.name
                                    }, id: \.code) { country in
                                        CountryCell(
                                            name: country.name,
                                            countryCode: country.code,
                                            flagAsset: country.flagAsset,
                                            isVisited: isVisited(country.code)
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, PassportTheme.Spacing.xxxl)
                    .padding(.horizontal, PassportTheme.Spacing.lg)
                }
            }
        }
        .background(PassportTheme.background)
        .toolbarVisibility(.hidden, for: .navigationBar)
    }
