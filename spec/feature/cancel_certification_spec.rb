require "rails_helper"

RSpec.feature "Cancel certification" do
  let!(:current_user) { User.authenticate! }

  let(:nod) { Generators::Document.build(type: "NOD") }
  let(:soc) { Generators::Document.build(type: "SOC") }
  let(:form9) { Generators::Document.build(type: "Form 9") }

  let(:appeal) do
    Generators::Appeal.build(
      vacols_record: {
        template: :ready_to_certify,
        nod_date: nod.received_at,
        soc_date: soc.received_at,
        form9_date: form9.received_at
      },
      documents: [nod, soc, form9]
    )
  end

  let(:appeal_mismatched_docs) do
    Generators::Appeal.build(
      vacols_record: {
        template: :ready_to_certify,
        nod_date: nod.received_at,
        soc_date: soc.received_at,
        form9_date: form9.received_at
      },
      documents: []
    )
  end

  scenario "Validate Input Fields" do
    visit "certifications/new/#{appeal.vacols_id}"
    click_on "Cancel Certification"
    expect(page).to have_content("Please explain why this case cannot be certified with Caseflow.")

    # Test validation errors
    within(".modal-container") do
      click_on "Cancel certification"
    end
    expect(page).to have_content("Make sure you've selected an option below.")
    expect(page).to have_content("Make sure you’ve entered a valid email address below.")

    within_fieldset("Why can't be this case certified in Caseflow") do
      find("label", text: "Other").click
    end
    fill_in "What's your VA email address?", with: "fk@va.gov"
    expect(page).to_not have_css(".usa-input-error")
    fill_in "What's your VA email address?", with: "fk@va"
    within(".modal-container") do
      click_on "Cancel certification"
    end
    expect(page).to have_content("Make sure you’ve filled out the comment box below.")
    expect(page).to have_content("Make sure you’ve entered a valid email address below.")

    within_fieldset("Why can't be this case certified in Caseflow") do
      find("label", text: "Other").click
    end
    fill_in "Tell us more about your situation.", with: " "
    within(".modal-container") do
      click_on "Cancel certification"
    end
    expect(page).to have_content("Make sure you’ve filled out the comment box below.")

    within_fieldset("Why can't be this case certified in Caseflow") do
      find("label", text: "Other").click
    end
    fill_in "Tell us more about your situation.", with: "Test"
    fill_in "What's your VA email address?", with: "fk@va.gov"
    expect(page).to_not have_css(".usa-input-error")
    within(".modal-container") do
      click_on "Cancel certification"
    end
    expect(page).to_not have_css(".usa-input-error")

    # Test resulting page
    expect(page).to have_content("The certification has been cancelled")

    # Test CertificationCancellation resulting record
    expect(CertificationCancellation.last.certification_id).to eq(Certification.last.id)
    expect(CertificationCancellation.last.cancellation_reason).to eq("Other")
    expect(CertificationCancellation.last.other_reason).to eq("Test")
    expect(CertificationCancellation.last.email).to eq("fk@va.gov")
  end

  scenario "Test Characters remaining" do
    visit "certifications/new/#{appeal.vacols_id}"
    click_on "Cancel Certification"
    within_fieldset("Why can't be this case certified in Caseflow") do
      find("label", text: "Other").click
    end
    fill_in "Tell us more about your situation.", with: "Test"
    expect(page).to have_content("1996 characters remaining")
    fill_in "Tell us more about your situation.", with:
        "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget
        dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur
        ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla
        consequat massa quis enim. Donec pede justo, fringilla vel, aliquet nec, vulputate eget, arcu.
        In enim justo, rhoncus ut, imperdiet a, venenatis vitae, justo. Nullam dictum felis eu pede
        mollis pretium. Integer tincidunt. Cras dapibus. Vivamus elementum semper nisi. Aenean
        vulputate eleifend tellus. Aenean leo ligula, porttitor eu, consequat vitae, eleifend ac,
        enim. Aliquam lorem ante, dapibus in, viverra quis, feugiat a, tellus. Phasellus viverra
        nulla ut metus varius laoreet. Quisque rutrum. Aenean imperdiet. Etiam ultricies nisi vel
        augue. Curabitur ullamcorper ultricies nisi. Nam eget dui. Etiam rhoncus. Maecenas tempus,
        tellus eget condimentum rhoncus, sem quam semper libero, sit amet adipiscing sem neque
        sedipsum. Nam quam nunc, blandit vel, luctus pulvinar, hendrerit id, lorem. Maecenas nec
        odio et ante tincidunt tempus. Donec vitae sapien ut libero venenatis faucibus. Nullam quis
        ante. Etiam sit amet orci eget eros faucibus tincidunt. Duis leo. Sed fringilla mauris sit
        amet nibh. Donec sodales sagittis magna. Sed consequat, leo eget bibendum sodales, augue
        velit cursus nunc, quis gravida magna mi a libero. Fusce vulputate eleifend sapien.
        Vestibulum purus quam, scelerisque ut, mollis sed, nonummy id, metus. Nullam accumsan
        lorem in dui. Cras ultricies mi eu turpis hendrerit fringilla. Vestibulum ante ipsum
        primis in faucibus orci luctus et ultrices posuere cubilia Curae; In ac dui quis mi
        consectetuer lacinia. Nam pretium turpis et arcu. Duis arcu tortor, suscipit eget,
        imperdiet nec, imperdiet iaculis, ipsum. Sed aliquam ultrices mauris. Integer ante arcu,
        accumsan a, consectetuer eget, posuere ut, mauris. Praesent adipiscing. Phasellus
        ullamcorper ipsum rutrum nunc. Nunc nonummy metus. Vestib"
    expect(page).to have_content("0 characters remaining")
    fill_in "Tell us more about your situation.", with:
        "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget
        dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur
        ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla
        consequat massa quis enim. Donec pede justo, fringilla vel, aliquet nec, vulputate eget, arcu.
        In enim justo, rhoncus ut, imperdiet a, venenatis vitae, justo. Nullam dictum felis eu pede
        mollis pretium. Integer tincidunt. Cras dapibus. Vivamus elementum semper nisi. Aenean
        vulputate eleifend tellus. Aenean leo ligula, porttitor eu, consequat vitae, eleifend ac,
        enim. Aliquam lorem ante, dapibus in, viverra quis, feugiat a, tellus. Phasellus viverra
        nulla ut metus varius laoreet. Quisque rutrum. Aenean imperdiet. Etiam ultricies nisi vel
        augue. Curabitur ullamcorper ultricies nisi. Nam eget dui. Etiam rhoncus. Maecenas tempus,
        tellus eget condimentum rhoncus, sem quam semper libero, sit amet adipiscing sem neque
        sedipsum. Nam quam nunc, blandit vel, luctus pulvinar, hendrerit id, lorem. Maecenas nec
        odio et ante tincidunt tempus. Donec vitae sapien ut libero venenatis faucibus. Nullam quis
        ante. Etiam sit amet orci eget eros faucibus tincidunt. Duis leo. Sed fringilla mauris sit
        amet nibh. Donec sodales sagittis magna. Sed consequat, leo eget bibendum sodales, augue
        velit cursus nunc, quis gravida magna mi a libero. Fusce vulputate eleifend sapien.
        Vestibulum purus quam, scelerisque ut, mollis sed, nonummy id, metus. Nullam accumsan
        lorem in dui. Cras ultricies mi eu turpis hendrerit fringilla. Vestibulum ante ipsum
        primis in faucibus orci luctus et ultrices posuere cubilia Curae; In ac dui quis mi
        consectetuer lacinia. Nam pretium turpis et arcu. Duis arcu tortor, suscipit eget,
        imperdiet nec, imperdiet iaculis, ipsum. Sed aliquam ultrices mauris. Integer ante arcu,
        accumsan a, consectetuer eget, posuere ut, mauris. Praesent adipiscing. Phasellus
        ullamcorper ipsum rutrum nunc. Nunc nonummy metus. Vestib{"
    expect(page).to have_content("0 characters remaining")
  end

  scenario "Click cancel when certification has mistmatched documents" do
    visit "certifications/new/#{appeal_mismatched_docs.vacols_id}"
    expect(page).to have_content("Not found")
    click_on "Cancel Certification"
    expect(page).to have_content("Please explain why this case cannot be certified with Caseflow.")
    within_fieldset("Why can't be this case certified in Caseflow") do
      find("label", text: "Missing document could not be found").click
    end
    fill_in "What's your VA email address?", with: "fk@va.gov"
    within(".modal-container") do
      click_on "Cancel certification"
    end
    expect(page).to have_content("The certification has been cancelled")
  end

  describe "Test json format of CerticationCancellationController" do
    before(:each) do
      @current_driver = Capybara.current_driver
      Capybara.current_driver = :rack_test
    end

    after(:each) do
      Capybara.current_driver = @current_driver
    end

    it "should response to json" do
      page.driver.post "/certification_cancellations", { "certification_cancellation" =>
        { "cancellation_reason" => "VBMS and VACOLS dates didn't match and couldn't be changed",
          "other_reason" => "", "email" => "test@gmail.com", "certification_id" => "2" } }, format: :json
      expect(page.driver.status_code).to be 302
      page.driver.post "/certification_cancellations", { "certification_cancellation" =>
        { "cancellation_reason" => "VBMS and VACOLS dates didn't match and couldn't be changed",
          "other_reason" => "", "email" => "test@gmail", "certification_id" => "2" } }, format: :json
      expect(page.driver.status_code).to be 500
    end
  end
end
