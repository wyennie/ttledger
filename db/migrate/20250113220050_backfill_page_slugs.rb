class BackfillPageSlugs < ActiveRecord::Migration[7.0]
  def up
    Page.find_each do |page|
      if page.slug.blank?
        page.slug = page.slug_candidates.first
        page.save!(validate: false)
      end
    end
  end

  def down
  end
end
